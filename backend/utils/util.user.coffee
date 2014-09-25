Promise = require 'bluebird'
querystring = require 'querystring'

logger = require '../config/logger'
config = require '../config/config'

userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'
sessionSecurityService = require '../services/service.sessionSecurity'
routes = require '../../common/config/routes'


doNextRedirect = (req, res) -> Promise.try () ->
  if req.query.next
    return res.redirect(req.query.next)
  else
    return res.redirect(routes.index)

cacheUserValues = (req) ->
  promises = []
  if not req.session.permissions
    logger.debug "trying to set permissions on session for user: #{req.user.username}"
    permissionsPromise = permissionsService.getPermissionsForUserId(req.user.id)
    .then (permissionsHash) ->
      logger.debug "permissions loaded on session for user: #{req.user.username}"
      req.session.permissions = permissionsHash
    promises.push permissionsPromise
  if not req.session.groups
    logger.debug "trying to set groups on session for user: #{req.user.username}"
    groupsPromise = permissionsService.getGroupsForUserId(req.user.id)
    .then (groupsHash) ->
      logger.debug "groups loaded on session for user: #{req.user.username}"
      req.session.groups = groupsHash
    promises.push groupsPromise
  return Promise.all(promises)
  .then () ->
    logger.debug "all user values cached for user: #{req.user.username}"
  .catch (err) ->
    logger.error "error caching user values for user: #{req.user.username}"
    Promise.reject(err)

checkLogin = (req, res, next) -> Promise.try () ->
  logger.debug "checking for already logged-in user"
  if not req.user then return next()
  logger.debug "existing session found for username: #{req.user.username}"
  return module.exports.doNextRedirect(req, res)

doLogin = (req, res, next) -> Promise.try () ->
  logger.debug "attempting to do login for username: #{req.body.username}"
  userService.verifyPassword(req.body.username, req.body.password)
  .catch (err) ->
    logger.debug "failed authentication: #{err}"
    return false
  .then (user) ->
    if not user
      req.query.errmsg = "Username and/or password does not match our records."
      return res.redirect("#{routes.logIn}?#{querystring.stringify(req.query)}")
    else
      req.user = user
      req.session.userid = user.id
      module.exports.cacheUserValues(req)
      .then () ->
        req.session.saveAsync()
      .then () ->
        sessionSecurityService.ensureSessionCount(req)
      .then () ->
        sessionSecurityService.createNewSeries(req, res)
      .then () ->
        module.exports.doNextRedirect(req, res)
  .catch (err) ->
    logger.error "unexpected error during doLogin(): #{err}"
    next(err)

doLogout = (req, res, next) -> Promise.try () ->
  logger.debug "attempting to log user out: #{req.user.username}"
  req.session.destroyAsync()
  .then () ->
    return module.exports.doNextRedirect(req, res)
  .catch (err) ->
    logger.error "error logging out user: #{err}"
    next(err)


module.exports =
  doNextRedirect: doNextRedirect
  cacheUserValues: cacheUserValues
  checkLogin: checkLogin
  doLogin: doLogin
  doLogout: doLogout
 