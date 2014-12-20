Promise = require 'bluebird'

logger = require '../../config/logger'
httpStatus = require '../../../common/utils/httpStatus'
sessionSecurityService = require '../../services/service.sessionSecurity'
userService = require '../../services/service.user'
userUtils = require '../../utils/util.user'
ExpressResponse = require '../../utils/util.expressResponse'
alertIds = require '../../../common/utils/enums/util.enums.alertIds'


# handle login authentication, and do all the things needed for a new login session
doLogin = (req, res, next) -> Promise.try () ->
  if req.user
    # someone is logging in over an existing session...  shouldn't normally happen, but we'll deal
    logger.debug "attempting to log user out (someone is logging in): #{req.user.username}"
    promise = sessionSecurityService.deleteSecurities(session_id: req.sessionID)
    .then () ->
      req.user = null
      req.session.regenerateAsync()
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
      req.session.userid = user.id
      userUtils.cacheUserValues(req)
      .then () ->
        req.session.saveAsync()
      .then () ->
        sessionSecurityService.ensureSessionCount(req)
      .then () ->
        sessionSecurityService.createNewSeries(req, res, !!req.body.remember_me)
      .then () ->
        getIdentity(req, res, next)
  .catch (err) ->
    logger.error "unexpected error during doLogin(): #{err}"
    next(err)


# everything we need to do for a logout gets encapsulated here
doLogout = (req, res, next) -> Promise.try () ->
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


getIdentity = (req, res, next) ->
  if req.user
    # here we should probaby return some things from the user's profile as well, such as name
    res.json
      identity:
        permissions: req.session.permissions
        groups: req.session.groups
        stateRecall: req.session.state
  else
    res.json
      identity: null

updateUserState = (req, res, next) ->
  userService.updateUserState(req.session, req.body)
  .then () ->
    res.send()
  .catch (err) ->
    logger.error "error updating user state via API: #{err}"
    next(err)


module.exports =
  doLogin: doLogin
  doLogout: doLogout
  getIdentity: getIdentity
  updateUserState: updateUserState
