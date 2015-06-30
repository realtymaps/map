Promise = require 'bluebird'

logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
sessionSecurityService = require '../services/service.sessionSecurity'
userService = require '../services/service.user'
userUtils = require '../utils/util.user'
ExpressResponse = require '../utils/util.expressResponse'
alertIds = require '../../common/utils/enums/util.enums.alertIds'
config = require '../config/config'
JSONStream = require 'JSONStream'
{methodExec} = require '../utils/util.route.helpers'

badRequest = (msg) ->
  new ExpressResponse(alert: {msg: msg}, httpStatus.BAD_REQUEST)

# handle login authentication, and do all the things needed for a new login session
login = (req, res, next) -> Promise.try () ->
  if req.user
    # someone is logging in over an existing session...  shouldn't normally happen, but we'll deal
    logger.debug "attempting to log user out (someone is logging in): #{req.user.username}"
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.user = null
      # logger.debug "attempting session regenerateAsync"
      req.session.regenerateAsync()
      # logger.debug "post session regenerateAsync"
  else
    promise = Promise.resolve()

  promise.then () ->
    if !req.body.password
      logger.debug "no password specified for login: #{req.body.username}"
      return false
    logger.debug "attempting to do login for username: #{req.body.username}"
    userService.verifyPassword(req.body.username, req.body.password)
  .catch (err) ->
    logger.debug "failed authentication: #{err}"
    return false
  .then (user) ->
    if not user
      return next new ExpressResponse(alert: {
        msg: "Username and/or password does not match our records."
        id: alertIds.loginFailure
      }, httpStatus.UNAUTHORIZED)
    else
      req.user = user
      logger.debug "session: #{req.session}"
      req.session.userid = user.id

      userUtils.cacheUserValues(req)
      .then () ->
        req.session.saveAsync()
      .then () ->
        sessionSecurityService.ensureSessionCount(req)
      .then () ->
        sessionSecurityService.createNewSeries(req, res, !!req.body.remember_me)
      .then () ->
        identity(req, res, next)
  .catch (err) ->
    logger.error "unexpected error during login(): #{err}"
    next(err)


# everything we need to do for a logout gets encapsulated here
# JWI: for some reason, my debug output seems to indicate the logout route is getting called twice for every logout.
# I have no idea why that is, but the second time it seems the user is already logged out.  Strange.
logout = (req, res, next) -> Promise.try () ->
  if req.user
    logger.debug "attempting to log user out: #{req.user.username}"
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


identity = (req, res, next) ->
  if req.user
    # here we should probaby return some things from the user's profile as well, such as name
    res.json
      identity:
        permissions: req.session.permissions
        groups: req.session.groups
        stateRecall: req.session.state
        environment: config.ENV
  else
    res.json
      identity: null


updateState = (req, res, next) ->
  userService.updateProfile(req.session, req.body)
  .then () ->
    res.send()
  .catch (err) ->
    logger.error "error updating user state via API: #{err}"
    next(err)


profiles = (req, res, next) ->
  methodExec req,
    GET: () ->
      auth_user_id = req.session.userid
      userService.getProfiles(auth_user_id)
      .pipe(JSONStream.stringify()).pipe(res)
    POST: () ->
      res.send()

module.exports =
  login: login
  logout: logout
  identity: identity
  updateState: updateState
  profiles: profiles
