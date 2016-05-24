querystring = require 'querystring'
Promise = require 'bluebird'
_ = require 'lodash'

logger = require('../config/logger').spawn('auth')
config = require '../config/config'
userSessionService = require '../services/service.userSession'
permissionsService = require '../services/service.permissions'
sessionSecurityService = require '../services/service.sessionSecurity'
permissionsUtil = require '../../common/utils/permissions'
userUtils = require '../utils/util.user'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require './util.expressResponse'
tables = require '../config/tables'


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
  .catch (err) ->
    return false

# everything we need to do for a logout gets encapsulated here
# JWI: for some reason, my debug output seems to indicate the logout route is getting called twice for every logout.
# I have no idea why that is, but the second time it seems the user is already logged out.  Strange.
# (nem) moved here to avoid circular dependency on userSession route
logout = (req, res, next) -> Promise.try () ->
  if req.user
    logger.debug "attempting to log user out: #{req.user.username}"
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
        return Promise.reject(new SessionSecurityError('user', "no session security cookie found for user #{req.user.username} on session: #{req.sessionID}", 'warn'))
      return Promise.reject(new SessionSecurityError('nothing', 'no session security cookie found for anonymous user', false))
    values = cookie.split('.')
    if values.length != 3
      if req.user
        return Promise.reject(new SessionSecurityError('user', "invalid session security cookie found for user #{req.user.username} on session: #{req.sessionID} / #{cookie}"))
      else
        return Promise.reject(new SessionSecurityError())
    context.cookieValues = {userId: parseInt(values[0]), sessionId: values[1], token: values[2]}

    if (req.user)
      if req.user.id != context.cookieValues.userId
        return Promise.reject(new SessionSecurityError('user', "cookie vs session userId mismatch for user #{req.user.username} on session: #{req.sessionID}"))
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
      return Promise.reject(new SessionSecurityError('user', "multiple session security objects found for user #{req.user?.username} on session: #{context.sessionId}"))
    if req.user
      return Promise.reject(new SessionSecurityError('session', "no session security objects found for user #{req.user.username} on session: #{context.sessionId}", 'warn'))
    else
      return Promise.reject(new SessionSecurityError('nothing', 'anonymous user with no session security', false))
  .then (security) ->
    if context.cookieValues.userId != security.user_id
      return Promise.reject(new SessionSecurityError('session', "cookie vs security userId mismatch for user #{req.user?.username} on session: #{context.sessionId}"))
    sessionSecurityService.hashToken(context.cookieValues.token, security.series_salt)
    .then (tokenHash) ->
      if req.user
        # this is a logged-in user, so validate
        if tokenHash != security.token
          return Promise.reject(new SessionSecurityError('session', "cookie vs security token mismatch for user #{req.user.username} on active session: #{context.sessionId}", 'warn'))
        return
      else
        # this isn't a logged-in user, so validate only if remember_me was set; if
        # we do validate, then we need to do some login work
        if not security.remember_me
          return Promise.reject(new SessionSecurityError('security', 'anonymous user with non-remember_me session security', 'debug'))
        if tokenHash != security.token
          return Promise.reject(new SessionSecurityError('user', "cookie vs security token mismatch for user #{cookieValues.user_id} on remember_me session: #{context.sessionId}", 'warn'))
        req.session.userid = context.cookieValues.userId
        getSessionUser(req)
        .then (user) ->
          req.user = user
          userUtils.cacheUserValues(req)
        .then () ->
          req.session.saveAsync()
        .then () ->
          sessionSecurityService.ensureSessionCount(req)
        .then () ->
          sessionSecurityService.createNewSeries(req, res, true)
  .catch SessionSecurityError, (err) ->
    # figure out what we need to invalidate and do it
    switch (err.invalidate)
      when 'security' then return sessionSecurityService.deleteSecurities(session_id: context.sessionId)
      when 'session' then invalidatePromise = sessionSecurityService.deleteSecurities(session_id: context.sessionId)
      when 'user' then invalidatePromise = sessionSecurityService.deleteSecurities(user_id: req.user.id)
      else return Promise.resolve() # "nothing" is a valid possibility
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
    if not req.user
      if options.redirectOnFail
        return res.json(doLogin: true)
      else
        return next new ExpressResponse(alert: {msg: "Please login to access #{req.path}."}, httpStatus.UNAUTHORIZED)
    return process.nextTick(next)

# route-specific middleware that requires profile and project for the user
requireProject = ({methods}) ->
  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod req.method, methods

    if !req.user?
      return next new ExpressResponse(alert: {msg: "Please login to access #{req.path}."}, httpStatus.UNAUTHORIZED)
    if !req.session?.current_profile_id?
      return next new ExpressResponse(alert: {msg: "Missing profile ID for #{req.path}."}, httpStatus.UNAUTHORIZED)
    if !req.session?.profiles?
      return next new ExpressResponse(alert: {msg: "No profiles found for user id #{req.user.id}."}, httpStatus.UNAUTHORIZED)
    if !req.session.profiles[req.session.current_profile_id]?
      return next new ExpressResponse(alert: {msg: "No profiles for user #{req.user.id} found for profile id #{req.session.current_profile_id}."}, httpStatus.UNAUTHORIZED)

    return process.nextTick(next)

# route-specific middleware that requires a user to be the editor (which would logically include
# parent but not always) of the given project being acted upon.  implies `requireProject` automatically
requireProjectEditor = ({methods, parentidparam}) ->
  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod req.method, methods

    # ensure project
    proj = requireProject {methods}
    proj req, res, () ->

      # procure profile (should exist by virtue of passing requireProject)
      profile = req.session.profiles[req.session.current_profile_id]

      # this is the actual parent check
      if profile.parent_auth_user_id? && profile.parent_auth_user_id != req.user.id
        return next new ExpressResponse(alert: {msg: "You must be the creator of this project."}, httpStatus.UNAUTHORIZED)

      return process.nextTick(next)

# route-specific middleware that requires a user to be the parent of the given project
# being acted upon.  implies `requireProject` automatically
requireProjectParent = ({methods, parentidparam}) ->
  # list-ize to defensively accept strings
  methods = [methods] if _.isString methods
  return (req, res, next) -> Promise.try () ->

    # middleware is not applicable for this req.method, move along
    return process.nextTick(next) if ignoreThisMethod req.method, methods

    # ensure project
    proj = requireProject {methods}
    proj req, res, () ->

      # procure profile (should exist by virtue of passing requireProject)
      profile = req.session.profiles[req.session.current_profile_id]

      # this is the actual parent check
      if profile.parent_auth_user_id? && profile.parent_auth_user_id != req.user.id
        return next new ExpressResponse(alert: {msg: "You must be the creator of this project."}, httpStatus.UNAUTHORIZED)

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
        return next new ExpressResponse(alert: {msg: "You do not have permission to access #{req.path}."}, httpStatus.UNAUTHORIZED)
    return process.nextTick(next)


module.exports =
  setSessionCredentials: setSessionCredentials
  checkSessionSecurity: checkSessionSecurity
  requireLogin: requireLogin
  requireProject: requireProject
  requireProjectParent: requireProjectParent
  requireProjectEditor: requireProjectEditor
  requirePermissions: requirePermissions
  logout: logout
