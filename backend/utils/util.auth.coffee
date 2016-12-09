Promise = require 'bluebird'
_ = require 'lodash'

logger = require('../config/logger').spawn('session')
config = require '../config/config'
sessionSecurityService = require '../services/service.sessionSecurity'
permissionsUtil = require '../../common/utils/permissions'
userUtils = require './util.user'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require './util.expressResponse'
tables = require '../config/tables'
analyzeValue = require '../../common/utils/util.analyzeValue'


class SessionSecurityError extends Error
  constructor: (@invalidate='nothing', @message, loglevel='error') ->
    @name = 'SessionSecurityError'
    if @message && loglevel
      if @invalidate is 'nothing'
        logger[loglevel] "SessionSecurityCheck: #{@message}"
      else
        logger[loglevel] "SessionSecurityCheck: invalidation triggered at #{@invalidate} level: #{@message}"


getSessionUser = (req) -> Promise.try () ->
  if not req.session.userid
    return Promise.resolve(false)
  tables.auth.user()
  .where(id: req.session.userid)
  .then (user=[]) ->
    user?[0] ? false
  .then (user) ->
    if user.mlses_verified?.length
      user.mlses_verified = _.uniq user.mlses_verified, true, (m) -> m.toUpperCase()
    user
  .catch (err) ->
    logger.warn analyzeValue.getFullDetails err
    return false

# everything we need to do for a logout gets encapsulated here
# JWI: for some reason, my debug output seems to indicate the logout route is getting called twice for every logout.
# I have no idea why that is, but the second time it seems the user is already logged out.  Strange.
# (nem) moved here to avoid circular dependency on userSession route
logout = (req, res, next) -> Promise.try () ->
  if req.user
    logger.debug () -> "attempting to log user out: #{req.user.username} (#{req.sessionID})"
    delete req.session.current_profile_id
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.session.destroyAsync()
  else
    promise = Promise.resolve()
  promise.then () ->
    return res.json(identity: null)
  .catch (err) ->
    logger.error "error logging out user: #{err}"
    next(err)

ignoreThisMethod = (thisMethod, methods) ->
  return !(_.some methods, (item) -> item.toUpperCase() == thisMethod)

#
# middleware function handlers
#


# this function gets used as app-wide middleware, so assume it will have run
# before any route gets called
setSessionCredentials = (req, res) ->
  getSessionUser(req).then (user) ->
    # set the user on the request
    logger.debug -> "setting user"
    logger.debug -> _.omit user, "password"
    req.user = user
    if req.user
      return userUtils.cacheUserValues(req)
  .catch (err) ->
    logger.error 'error while setting session data on request'
    Promise.reject(err)

# app-wide middleware to implement remember_me functionality
checkSessionSecurity = (req, res) ->
  context = {}

  Promise.try () ->
    cookie = req.signedCookies[config.SESSION_SECURITY.name]
    if not cookie
      if req.user
        throw new SessionSecurityError('user', "no session security cookie found for user #{req.user.username} on session: #{req.sessionID}", 'warn')
      throw new SessionSecurityError('nothing', 'no session security cookie found for anonymous user', false)
    values = cookie.split('.')
    if values.length != 3
      if req.user
        throw new SessionSecurityError('user', "invalid session security cookie found for user #{req.user.username} on session: #{req.sessionID} / #{cookie}")
      else
        throw new SessionSecurityError()
    context.cookieValues = {userId: parseInt(values[0]), sessionId: values[1], token: values[2]}

    if (req.user)
      if req.user.id != context.cookieValues.userId
        throw new SessionSecurityError('user', "cookie vs session userId mismatch for user #{req.user.username} on session: #{req.sessionID}")
      context.sessionId = req.sessionID
    else
      context.sessionId = context.cookieValues.sessionId

  .then () ->
    sessionSecurityService.getSecuritiesForSession(context.sessionId)
  .then (securities) ->
    if securities.length == 1
      # this is the happy path
      return securities[0]
    if securities.length > 1
      throw new SessionSecurityError('user', "multiple session security objects found for user #{req.user?.username} on session: #{context.sessionId}")
    if req.user
      throw new SessionSecurityError('session', "no session security objects found for user #{req.user.username} on session: #{context.sessionId}", 'warn')
    else
      throw new SessionSecurityError('nothing', 'anonymous user with no session security', false)
  .then (security) ->
    if context.cookieValues.userId != security.user_id
      throw new SessionSecurityError('session', "cookie vs security userId mismatch for user #{req.user?.username} on session: #{context.sessionId}")
    sessionSecurityService.hashToken(context.cookieValues.token, security.series_salt)
    .then (tokenHash) ->
      if req.user
        # this is a logged-in user, so validate
        if tokenHash != security.token
          throw new SessionSecurityError('session', "cookie vs security token mismatch for user #{req.user.username} on active session: #{context.sessionId}", 'warn')
        return
      else
        # this isn't a logged-in user, so validate only if remember_me was set; if
        # we do validate, then we need to do some login work
        if not security.remember_me
          throw new SessionSecurityError('security', 'anonymous user with non-remember_me session security', 'debug')
        if tokenHash != security.token
          throw new SessionSecurityError('user', "cookie vs security token mismatch for user #{context.cookieValues.userId} on remember_me session: #{context.sessionId}", 'warn')

        req.session.userid = context.cookieValues.userId
        getSessionUser(req)
        .then (user) ->
          sessionSecurityService.sessionLoginProcess(req, res, user, rememberMe: true)

  .catch SessionSecurityError, (err) ->
    # figure out what we need to invalidate and do it
    switch (err.invalidate)
      when 'security'
        return sessionSecurityService.deleteSecurities(session_id: context.sessionId)
      when 'session'
        invalidatePromise = sessionSecurityService.deleteSecurities(session_id: context.sessionId)
      when 'user'
        invalidatePromise = sessionSecurityService.deleteSecurities(user_id: req.user.id)
      else
        return Promise.resolve() # "nothing" is a valid possibility
    return invalidatePromise.then () ->
      req.session.destroyAsync()
    .then () ->
      delete req.user
      delete req.sessionID
      delete req.session
      res.clearCookie config.SESSION_SECURITY.name, config.SESSION_SECURITY
  .catch (err) ->
    logger.error "error doing session security checks: #{err}"
    Promise.reject(err)


# route-specific middleware that requires a login, and either responds with
# a 401 or a login redirect on failure, based on the options.
#   options:
#     redirectOnFail: whether to redirect to the login page, default false
requireLogin = (options = {}) ->
  defaultOptions =
    redirectOnFail: false
  options = _.merge(defaultOptions, options)
  return (req, res, next) -> Promise.try () ->
    if !req.user
      if options.redirectOnFail
        return res.json(doLogin: true)
      else
        return next new ExpressResponse(alert: {msg: "Please login to access #{req.path}."}, {quiet: true, status: httpStatus.UNAUTHORIZED})
    return process.nextTick(next)

# route-specific middleware that requires profile and project for the user
# optional: methods
# optional: projectIdParam (needs to match the id of the endpoint, such as `id` or `project_id`)
#           Can use format like `body.project_id` or `params.id` to force where on `req` to get the id.
requireProject = ({methods, projectIdParam, getProjectFromSession = false} = {}) ->
  methods ?= ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if projectIdParam == undefined
    projectIdParam = 'id'

  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod(req.method, methods)

    # get project id based on the `projectIdParam` argument in either `req.params` or
    #   `req.query`, whichever, with precedence given to explicit path value by the user-defined
    #   `projectIdParam` on the `req` obj,     followed by `req.params`, since
    #   that is where the restful resource id will often be found (in url)
    queryParams = _.merge {}, req.query, req.params

    # get profile based on project param.  some endpoints will not have this,
    # so if project is not present, get it via `current_profile_id` off session
    if getProjectFromSession != true and queryParams? and projectIdParam of queryParams
      project_id = _.get(req, projectIdParam, queryParams[projectIdParam]) # try using `projectIdParam as a "path" if possible
      profile = _.find(req.session.profiles, project_id: Number(project_id)) # project_id == null, undefined, or NaN makes `profile` undefined here
    else
      profile = req.session.profiles["#{req.session.current_profile_id}"]

    # auth-ing
    if !profile?
      return next new ExpressResponse(alert: {msg: "You are unauthorized to access this project."}, {status: httpStatus.UNAUTHORIZED})
    if !req.user?
      return next new ExpressResponse(alert: {msg: "Please login to access #{req.path}."}, {quiet: true, status: httpStatus.UNAUTHORIZED})
    if !req.session?.profiles? or Object.keys(req.session.profiles).length == 0
      return next new ExpressResponse(alert: {msg: "You need to create or be invited to a project to do that."}, {status: httpStatus.UNAUTHORIZED})

    # attach to req for other project-oriented middlewares to use
    req.rmapsProfile = profile

    return process.nextTick(next)

# route-specific middleware that requires a user to be the editor (which would logically include
# parent but not always) of the given project being acted upon.  implies `requireProject` automatically
# optional: methods
# optional: projectIdParam (needs to match the url param of the endpoint, though)
requireProjectEditor = ({methods, projectIdParam, getProjectFromSession = false} = {}) ->
  methods ?= ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if projectIdParam == undefined
    projectIdParam = 'id'

  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # if middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod(req.method, methods)

    # ensure project
    proj = requireProject({methods, projectIdParam, getProjectFromSession})
    proj(req, res, () ->

      # profile is on req courtesy of `requireProject`
      profile = req.rmapsProfile

      # auth-ing
      if !profile?.can_edit
        return next new ExpressResponse(alert: {msg: "You are not authorized to edit this project."}, {status: httpStatus.UNAUTHORIZED})

      return process.nextTick(next)
    )

# route-specific middleware that requires a user to be the parent of the given project
# being acted upon.  implies `requireProject` automatically
# optional: methods
# optional: projectIdParam (needs to match the url param of the endpoint, though)
requireProjectParent = ({methods, projectIdParam, getProjectFromSession = false} = {}) ->
  methods ?= ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if projectIdParam == undefined
    projectIdParam = 'id'

  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # if middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod(req.method, methods)

    # ensure project
    proj = requireProject({methods, projectIdParam, getProjectFromSession})
    proj(req, res, () ->

      # profile is on req courtesy of `requireProject`
      profile = req.rmapsProfile

      # auth-ing
      if !profile? or (profile.parent_auth_user_id? && profile.parent_auth_user_id != req.user.id)
        return next new ExpressResponse(alert: {msg: "You must be the creator of this project."}, {status: httpStatus.UNAUTHORIZED})

      return process.nextTick(next)
    )

# route-specific middleware that requires a user to have an active, paid subscription
# optional: methods
# optional: projectIdParam (needs to match the url param of the endpoint, though)
requireSubscriber = ({methods} = {}) ->
  methods ?= ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']

  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # if middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod(req.method, methods)

    # there are a variety of statuses that imply grace periods,
    # trial, type of plan, etc so we just test for the inactive statuses.
    if !userUtils.isSubscriber(req)
      return next new ExpressResponse(alert: {msg: "A subscription is required to do this."}, {status: httpStatus.UNAUTHORIZED})

    return process.nextTick(next)

# route-specific middleware that requires permissions set on the session,
# and either responds with a 401 or a logout redirect on failure, based on
# the options passed:
#   permissions:
#     parameter specifying what permission(s) the user needs in order to
#     access the given route; can either be a single string, or an object
#     with either "any" or "all" as a key and an array of strings as a value
#   options:
#     logoutOnFail: whether force a logout on failure, default false
requirePermissions = (permissions, options = {}) ->
  defaultOptions =
    logoutOnFail: false
  options = _.merge(defaultOptions, options)
  # don't allow strange inputs
  if typeof(permissions) == 'object'
    if permissions.all and permissions.any
      throw new Error("Both 'all' and 'any' permission semantics may not be used on the same route.")
    if not permissions.all and not permissions.any
      throw new Error('No permissions specified.')
  else if typeof(permissions) != 'string'
    throw new Error('Bad permissions object')
  return (req, res, next) -> Promise.try () ->
    if not permissionsUtil.checkAllowed(permissions, req.session.permissions, logger.debug)
      logger.warn "access denied to username #{req.user.username} for URI: #{req.originalUrl}"
      if options.logoutOnFail
        return logout(req, res, next)
      else
        return next new ExpressResponse(alert: {msg: "You do not have permission to access #{req.path}."}, {quiet: true, status: httpStatus.UNAUTHORIZED})
    return process.nextTick(next)


# for now this is a no-op, because session stuff gets automatically added when any route-specific middleware is
# configured -- this is a placeholder to be used when we just need to trigger session middleware inclusion
sessionSetup = (req, res, next) ->
  process.nextTick(next)


module.exports = {
  setSessionCredentials
  checkSessionSecurity
  requireLogin
  requireProject
  requireProjectParent
  requireProjectEditor
  requirePermissions
  requireSubscriber
  logout
  sessionSetup
}
