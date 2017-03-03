Promise = require 'bluebird'
_ = require 'lodash'
moment = require 'moment'
memoize = require 'memoizee'

logger = require('../config/logger').spawn('session')
config = require '../config/config'
tz = require '../config/tz'
sessionSecurityService = require '../services/service.sessionSecurity'
permissionsUtil = require '../../common/utils/permissions'
userUtils = require './util.user'
tables = require '../config/tables'
analyzeValue = require '../../common/utils/util.analyzeValue'
{NeedsLoginError, PermissionsError} = require './errors/util.errors.userSession'
profileErrors = require './errors/util.error.profile'
ExpressResponse = require './util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'

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
logout = (req) ->
  Promise.try () ->
    if req.user
      logger.debug () -> "attempting to log user out: #{req.user.email} (#{req.sessionID})"
      delete req.session.current_profile_id
      sessionSecurityService.deleteSecurities(session_id: req.sessionID)
      .then () ->
        req.session.destroyAsync()
  .catch (err) ->
    logger.error "error logging out user: #{err}"
    throw err

ignoreThisMethod = (thisMethod, methods) ->
  return !(_.some methods, (item) -> item.toUpperCase() == thisMethod)

#
# middleware function handlers
#


# this function gets used as app-wide middleware, so assume it will have run
# before any route gets called
setSessionCredentials = (req) ->
  getSessionUser(req).then (user) ->
    # set the user on the request
    req.user = user
    if req.user
      return userUtils.cacheUserValues(req)
  .catch profileErrors.NoProfileFoundError, profileErrors.NoProfileFoundError.handle(req)
  .catch (err) ->
    logger.error 'error while setting session data on request'
    throw err

# app-wide middleware to implement remember_me functionality
checkSessionSecurity = (req, res) ->
  context = {}

  Promise.try () ->
    cookie = req.signedCookies[config.SESSION_SECURITY.name]
    if not cookie
      if req.user
        throw new SessionSecurityError('user', "no session security cookie found for user #{req.user.email} on session: #{req.sessionID}", 'warn')
      throw new SessionSecurityError('nothing', 'no session security cookie found for anonymous user', false)
    values = cookie.split('.')
    if values.length != 3
      if req.user
        throw new SessionSecurityError('user', "invalid session security cookie found for user #{req.user.email} on session: #{req.sessionID} / #{cookie}")
      else
        throw new SessionSecurityError()
    context.cookieValues = {userId: parseInt(values[0]), sessionId: values[1], token: values[2]}

    if (req.user)
      if req.user.id != context.cookieValues.userId
        throw new SessionSecurityError('user', "cookie vs session userId mismatch for user #{req.user.email} on session: #{req.sessionID}")
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
      throw new SessionSecurityError('user', "multiple session security objects found for user #{req.user?.email} on session: #{context.sessionId}")
    if req.user
      throw new SessionSecurityError('session', "no session security objects found for user #{req.user.email} on session: #{context.sessionId}", 'warn')
    else
      throw new SessionSecurityError('nothing', 'anonymous user with no session security', false)
  .then (security) ->
    if context.cookieValues.userId != security.user_id
      throw new SessionSecurityError('session', "cookie vs security userId mismatch for user #{req.user?.email} on session: #{context.sessionId}")
    sessionSecurityService.hashToken(context.cookieValues.token, security.series_salt)
    .then (tokenHash) ->
      if req.user
        # this is a logged-in user, so validate
        if tokenHash != security.token
          throw new SessionSecurityError('session', "cookie vs security token mismatch for user #{req.user.email} on active session: #{context.sessionId}", 'warn')
        return

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
    redirectOnFail: true
  options = _.extend({}, defaultOptions, options)
  result = (req) -> Promise.try () ->
    logger.debug "MIDDLEWARE: requireLogin"
    if !req.user
      if options.redirectOnFail
        throw new ExpressResponse({doLogin: true}, {quiet: true})
      else
        throw new NeedsLoginError("Please login to access #{req.path}.")
  result.inspect = () -> "requireLogin(#{analyzeValue.simpleInspect(options)})"
  result


# route-specific middleware that requires profile and project for the user
# optional: methods
# optional: projectIdParam (needs to match the id of the endpoint, such as `id` or `project_id`)
#           Can use format like `body.project_id` or `params.id` to force where on `req` to get the id.
requireProject = (options = {}) ->
  defaultOptions =
    methods: ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']
    getProjectFromSession: false
  options = _.extend({}, defaultOptions, options)

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if options.projectIdParam == undefined
    options.projectIdParam = 'id'

  # list-ize to defensively accept strings
  options.methods = [options.methods] if _.isString options.methods

  {methods, projectIdParam, getProjectFromSession} = options

  result = (req) -> Promise.try () ->

# middleware is not applicable for this req.method, move along
    if ignoreThisMethod(req.method, methods)
      return

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
      throw new PermissionsError("You are unauthorized to access this project.")
    if !req.user?
      throw new NeedsLoginError("Please login to access #{req.path}.")
    if !req.session?.profiles? or Object.keys(req.session.profiles).length == 0
      throw new PermissionsError("You need to create or be invited to a project to do that.")

    # attach to req for other project-oriented middlewares to use
    req.rmapsProfile = profile

  result.inspect = () -> "requireProject(#{analyzeValue.simpleInspect(options)})"
  result


# route-specific middleware that requires access to the project corresponding to the mail campaign corresponding to the letter
# optional: methods
# optional: letterIdParam (needs to match the id of the endpoint, such as `id` or `letter_id`)
#           Can use format like `body.letter_id` or `params.id` to force where on `req` to get the id.
requireLetterProject = (options = {}) ->
  defaultOptions =
    methods: ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']
  options = _.extend({}, defaultOptions, options)

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if options.letterIdParam == undefined
    options.letterIdParam = 'id'

  # list-ize to defensively accept strings
  options.methods = [options.methods] if _.isString options.methods

  {methods, letterIdParam} = options

  result = (req) -> Promise.try () ->

    # middleware is not applicable for this req.method, move along
    if ignoreThisMethod(req.method, methods)
      return

    # get letter id based on the `letterIdParam` argument in either `req.params` or
    #   `req.query`, whichever, with precedence given to explicit path value by the user-defined
    #   `letterIdParam` on the `req` obj, followed by `req.params`, since
    #   that is where the restful resource id will often be found (in url)
    queryParams = _.merge {}, req.query, req.params

    tables.mail.campaign().select([
      "#{tables.mail.campaign.tableName}.project_id AS project_id"
      "#{tables.mail.letters.tableName}.lob_response as lob_response"
    ])
    .join("#{tables.mail.letters.tableName}", () ->
      this.on("#{tables.mail.campaign.tableName}.id", "#{tables.mail.letters.tableName}.user_mail_campaign_id")
    )
    .where("#{tables.mail.letters.tableName}.id": queryParams[letterIdParam])
    .then ([target]) ->
      profile = _.find(req.session.profiles, project_id: Number(target.project_id)) # project_id == null, undefined, or NaN makes `profile` undefined here

      # auth-ing
      if !profile?
        throw new PermissionsError("You are unauthorized to access the project associated with this letter.")
      if !req.user?
        throw new NeedsLoginError("Please login to access #{req.path}.")

      req.lobLetterId = target.lob_response.id

  result.inspect = () -> "requireLetter(#{analyzeValue.simpleInspect(options)})"
  result

# route-specific middleware that requires a user to be the editor (which would logically include
# parent but not always) of the given project being acted upon.  implies `requireProject` automatically
# optional: methods
# optional: projectIdParam (needs to match the url param of the endpoint, though)
requireProjectEditor = (options = {}) ->
  defaultOptions =
    methods: ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']
    getProjectFromSession: false
  options = _.extend({}, defaultOptions, options)

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if options.projectIdParam == undefined
    options.projectIdParam = 'id'

  # list-ize to defensively accept strings
  options.methods = [options.methods] if _.isString options.methods
  {methods, projectIdParam, getProjectFromSession} = options

  result = (req, res) -> Promise.try () ->

    # if middleware is not applicable for this req.method, move along
    if ignoreThisMethod(req.method, methods)
      return

    # ensure project
    requireProject({methods, projectIdParam, getProjectFromSession})(req, res)
    .then () ->

      # profile is on req courtesy of `requireProject`
      profile = req.rmapsProfile

      # auth-ing
      if !profile?.can_edit
        throw new PermissionsError("You are not authorized to edit this project.")

  result.inspect = () -> "requireProjectEditor(#{analyzeValue.simpleInspect(options)})"
  result

# route-specific middleware that requires a user to be the parent of the given project
# being acted upon.  implies `requireProject` automatically
# optional: methods
# optional: projectIdParam (needs to match the url param of the endpoint, though)
requireProjectParent = (options = {}) ->
  defaultOptions =
    methods: ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']
    getProjectFromSession: false
  options = _.extend({}, defaultOptions, options)

  # use default projectIdParam only for undefined; null is a valid option that can force use of session params
  if options.projectIdParam == undefined
    options.projectIdParam = 'id'

  # list-ize to defensively accept strings
  options.methods = [options.methods] if _.isString options.methods
  {methods, projectIdParam, getProjectFromSession} = options

  result = (req, res) -> Promise.try () ->

    # if middleware is not applicable for this req.method, move along
    if ignoreThisMethod(req.method, methods)
      return

    # ensure project
    requireProject({methods, projectIdParam, getProjectFromSession})(req, res)
    .then () ->

      # profile is on req courtesy of `requireProject`
      profile = req.rmapsProfile

      # auth-ing
      if !profile? or (profile.parent_auth_user_id? && profile.parent_auth_user_id != req.user.id)
        throw new PermissionsError("You must be the creator of this project.")

  result.inspect = () -> "requireProjectParent(#{analyzeValue.simpleInspect(options)})"
  result

# route-specific middleware that requires a user to have an active, paid subscription
# optional: methods
requireSubscriber = (options = {}) ->
  defaultOptions =
    methods: ['GET', 'PUT', 'POST', 'DELETE', 'PATCH']
  options = _.extend({}, defaultOptions, options)

  # list-ize to defensively accept strings
  options.methods = [options.methods] if _.isString options.methods
  {methods} = options

  result = (req) -> Promise.try () ->

    # if middleware is not applicable for this req.method, move along
    if ignoreThisMethod(req.method, methods)
      return

    # there are a variety of statuses that imply grace periods,
    # trial, type of plan, etc so we just test for the inactive statuses.
    if !userUtils.isSubscriber(req)
      throw new PermissionsError("A subscription is required to do this.")

  result.inspect = () -> "requireSubscriber(#{analyzeValue.simpleInspect(options)})"
  result

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
    logoutOnFail: true
  options = _.merge(defaultOptions, options)
  # don't allow strange inputs
  if typeof(permissions) == 'object'
    if permissions.all and permissions.any
      throw new Error("Both 'all' and 'any' permission semantics may not be used on the same route.")
    if not permissions.all and not permissions.any
      throw new Error('No permissions specified.')
  else if typeof(permissions) != 'string'
    throw new Error('Bad permissions object')
  result = (req, res) -> Promise.try () ->
    logger.debug "MIDDLEWARE: requirePermissions"
    if not permissionsUtil.checkAllowed(permissions, req.session.permissions, logger.debug)
      logger.warn "access denied to user #{req.user.email} for URI: #{req.originalUrl}"
      if options.logoutOnFail
        logout(req)
        .finally ->
          throw new ExpressResponse({identity: null}, {quiet: true})
      else
        throw new PermissionsError("You do not have permission to access #{req.path}.")
  result.inspect = () -> "requirePermissions(#{analyzeValue.simpleInspect(options)})"
  result


# for now this is a no-op, because session stuff gets automatically added when any route-specific middleware is
# configured -- this is a placeholder to be used when we just need to trigger session middleware inclusion
# Essentially a noop function to get the session possibly set
sessionSetup = () -> Promise.try () ->  # no-op
sessionSetup.inspect = () -> "sessionSetup()"


_getCurrentDateString = () ->
  moment.utc().utcOffset(tz.MOMENT_UTC_OFFSET).startOf('day').format('YYYY-MM-DD')
_getCurrentDateString = memoize(_getCurrentDateString, maxAge: 5*60*1000)

markActiveDate = (req, res) -> Promise.try () ->
  if !req.user
    return
  today = _getCurrentDateString()
  if moment.utc(req.user.last_active).format('YYYY-MM-DD') == today
    return
  req.user.last_active = today
  tables.auth.user()
  .where(id: req.user.id)
  .update(last_active: today)
markActiveDate.inspect = () -> "markActiveDate()"



module.exports = {
  setSessionCredentials
  checkSessionSecurity
  requireLogin
  requireProject
  requireLetterProject
  requireProjectParent
  requireProjectEditor
  requirePermissions
  requireSubscriber
  logout
  sessionSetup
  markActiveDate
}
