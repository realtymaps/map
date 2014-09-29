querystring = require 'querystring'
Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
config = require '../config/config'
userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'
sessionSecurityService = require '../services/service.sessionSecurity'
routes = require '../../common/config/routes'
userUtils = require '../utils/util.user'


class SessionSecurityError extends Error
  constructor: (@invalidate="nothing", @message, loglevel="error") ->
    @name = "SessionSecurityError"
    if @message
      if @invalidate is "nothing"
         logger[loglevel] "SessionSecurityCheck: #{@message}"
      else
        logger[loglevel] "SessionSecurityCheck: invalidation triggered at #{@invalidate} level: #{@message}"


getSessionUser = (req) -> Promise.try () ->
  if not req.session.userid
    return Promise.resolve(false)
  return userService.getUser(id: req.session.userid)
  .catch (err) ->
    return false
    
module.exports = {

  # this function gets used as app-wide middleware, so assume it will have run
  # before any route gets called
  setSessionCredentials: (req, res) ->
    getSessionUser(req).then (user) ->
      # set the user on the request
      req.user = user
      if req.user
        return userUtils.cacheUserValues(req)
    .catch (err) ->
      logger.error "error while setting session data on request"
      Promise.reject(err)
  
  checkSessionSecurity: (req, res) ->
    context = {}
    
    Promise.resolve()
    .then () ->
      cookie = req.signedCookies[config.SESSION_SECURITY.name]
      if not cookie
        if req.user
          return Promise.reject(new SessionSecurityError("user", "no session security cookie found for user #{req.user.username} on session: #{req.sessionID}", "warn"))
        return Promise.reject(new SessionSecurityError("nothing", "no session security cookie found for anonymous user", "debug"))
      values = cookie.split('.')
      if values.length != 3
        if req.user
          return Promise.reject(new SessionSecurityError("user", "invalid session security cookie found for user #{req.user.username} on session: #{req.sessionID} / #{cookie}"))
        else
          return Promise.reject(new SessionSecurityError())
      context.cookieValues = {userId: parseInt(values[0]), sessionId: values[1], token: values[2]}
      logger.debug "SessionSecurityCheck: ============================================================== cookieValues"
      logger.debug "SessionSecurityCheck: #{JSON.stringify(context.cookieValues, null, 2)}"
      logger.debug "SessionSecurityCheck: ============================================================== cookieValues"
      
      if (req.user)
        if req.user.id != context.cookieValues.userId
          return Promise.reject(new SessionSecurityError("user", "cookie vs session userId mismatch for user #{req.user.username} on session: #{req.sessionID}"))
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
        return Promise.reject(new SessionSecurityError("user", "multiple session security objects found for user #{req.user?.username} on session: #{context.sessionId}"))
      if req.user
        return Promise.reject(new SessionSecurityError("session", "no session security objects found for user #{req.user.username} on session: #{context.sessionId}", "warn"))
      else
        return Promise.reject(new SessionSecurityError("nothing", "anonymous user with no session security", "debug"))
    .then (security) ->
      logger.debug "SessionSecurityCheck: ============================================================== security"
      logger.debug "SessionSecurityCheck: #{JSON.stringify(security, null, 2)}"
      logger.debug "SessionSecurityCheck: ============================================================== security"
      if context.cookieValues.userId != security.user_id
        return Promise.reject(new SessionSecurityError("session", "cookie vs security userId mismatch for user #{req.user?.username} on session: #{context.sessionId}"))
      sessionSecurityService.hashToken(context.cookieValues.token, security.series_salt)
      .then (tokenHash) ->
        logger.debug "SessionSecurityCheck: ============================================================== tokenHash"
        logger.debug "SessionSecurityCheck: #{JSON.stringify(tokenHash, null, 2)}"
        logger.debug "SessionSecurityCheck: ============================================================== tokenHash"
        if req.user
          # this is a logged-in user, so validate on any of the 3 tokens (with
          # time restriction on the later 2), and iterate only on the first
          if tokenHash == security.next_security_token
            # yay! this is what we hope to see most of the time
            return sessionSecurityService.iterateSecurity(req, res, security)
          validUpdateTimestamp = Date.now()-config.SESSION_SECURITY.window
          if security.updated_at < validUpdateTimestamp
            return Promise.reject(new SessionSecurityError("session", "cookie vs security token mismatch (token timeout) for user #{req.user?.username} on session: #{context.sessionId}", "warn"))
          if tokenHash == security.current_security_token
            # ok, there were some simultaneous calls, we'll let it go
            return Promise.resolve()
          if tokenHash == security.previous_security_token
            # eh... it's possible this can happen, even though it would require the server 
            # to be misbehaving on some race conditions... just to play it safe we'll allow it
            logger.warn "relied on previous security token for authentication for user #{req.user.username} on session: #{req.sessionID}...  is the server overloaded?"
            return Promise.resolve()
          return Promise.reject(new SessionSecurityError("session", "cookie vs security token mismatch for user #{req.user.username} on session: #{context.sessionId}", "warn"))
        else
          # this isn't a logged-in user, so validate only if remember_me was set, and only
          # on the first 2 tokens (with no time restriction); if we do validate, then we
          # need to do some login work
          if not security.remember_me
            return Promise.reject(new SessionSecurityError("security", "anonymous user with non-remember_me session security", "debug"))
          if tokenHash != security.next_security_token && tokenHash != security.current_security_token
            return Promise.reject(new SessionSecurityError("user", "cookie vs security token mismatch for user #{cookieValues.user_id} on session: #{context.sessionId}", "warn"))
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
            sessionSecurityService.createNewSeries(req, res)
    .catch SessionSecurityError, (err) ->
      switch (err.invalidate)
        when "nothing" then return Promise.resolve()
        when "security" then return sessionSecurityService.deleteSecurities(session_id: context.sessionId)
        when "session" then invalidatePromise = sessionSecurityService.deleteSecurities(session_id: context.sessionId)
        when "user" then invalidatePromise = sessionSecurityService.deleteSecurities(user_id: req.user.id)
      return invalidatePromise.then () ->
        req.session.destroyAsync()
      .then () ->
        delete req.user
        delete req.sessionID
        delete req.session
        res.clearCookie config.SESSION_SECURITY.name, config.SESSION_SECURITY
    .catch (err) ->
      logger.debug "error doing session security checks: #{err}"
      Promise.reject(err)


# route-specific middleware that requires a login, and either responds with
# a 401 or a login redirect on failure, based on the options.
#   options:
#     redirectOnFail: whether to redirect to the login page, default false
  requireLogin: (options = {}) ->
    defaultOptions =
      redirectOnFail: false
    options = _.merge(defaultOptions, options)
    return (req, res, next) -> Promise.try () ->
      if not req.user
        if options.redirectOnFail
          return res.redirect("#{routes.logIn}?#{querystring.stringify(next: req.originalUrl)}")
        else
          return res.status(401).send("Please login to access this URI.")
      return process.nextTick(next)

# route-specific middleware that requires permissions set on the session,
# and either responds with a 401 or a logout redirect on failure, based on
# the options passed:
#   permissions:
#     parameter specifying what permission(s) the user needs in order to
#     access the given route; can either be a single string, or an object
#     with either "any" or "all" as a key and an array of strings as a value  
#   options:
#     logoutOnFail: whether to redirect to the logout page, default false
  requirePermissions: (permissions, options = {}) ->
    defaultOptions =
      logoutOnFail: false
    options = _.merge(defaultOptions, options)
    if typeof(permissions) is "string"
      permissions = { any: [permissions] }
    # don't allow strange inputs
    if permissions.all and permissions.any
      throw new Error("Both 'all' and 'any' permission semantics may not be used on the same route.")
    if not permissions.all and not permissions.any
      throw new Error("No permissions specified.")
    return (req, res, next) -> Promise.try () ->
      granted = false
      if req.session.permissions
        if permissions.any
          # we only need one of the permissions in the array
          for permission in permissions.any
            if req.session.permissions[permission]
              logger.debug "access allowed because user has '#{permission}' permission"
              granted = true
              break
        else if permissions.all
          # we need all the permissions in the array
          granted = true
          for permission in permissions.all
            if not req.session.permissions[permission]
              logger.debug "access denied because user lacks '#{permission}' permission"
              granted = false
              break
      if not granted
        logger.warn "access denied to username #{req.user.username} for URI: #{req.originalUrl}"
        if options.logoutOnFail
          return userUtils.doLogout(req, res, next)
        else
          return res.status(401).send("You do not have permission to access this URI.")
      return process.nextTick(next)
}
