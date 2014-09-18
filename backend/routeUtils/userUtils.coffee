Promise = require 'bluebird'
querystring = require 'querystring'

logger = require '../config/logger'
config = require '../config/config'

userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'
sessionSecurityService = require '../services/service.sessionSecurity'
routes = require '../../common/config/routes'


module.exports = {
  
  doLoginRedirect: (req, res) -> Promise.try () ->
    if req.query.next
      return res.redirect(req.query.next)
    else
      return res.redirect(routes.index)
  
  checkLogin: (req, res, next) -> Promise.try () ->
    logger.debug "checking for already logged-in user"
    if not req.user then return next()
    logger.debug "existing session found for username: #{req.user.username}"
    return module.exports.doLoginRedirect(req, res)
  
  doLogin: (req, res, next) -> Promise.try () ->
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
          req.session.userid = user.id
          if req.body.remember_me
            logger.debug "setting remember_me for user: #{user.username}"
          return sessionSecurityService.createNewSeries(req, res)
            .then () ->
              logger.debug "trying to set permissions on session for user: #{user.username}"
              return permissionsService.getPermissionsForUserId(user.id)
            .then (permissionsHash) ->
              logger.debug "permissions loaded on session for user: #{user.username}"
              req.session.permissions = permissionsHash
              return module.exports.doLoginRedirect(req, res)
      .catch (err) ->
        logger.error "unexpected error during doLogin(): #{err}"
        next(err)
  
  doLogout: (req, res, next) -> Promise.try () ->
    logger.debug "attempting to log user out: #{req.user.username}"
    req.session.destroyAsync()
      .then () ->
        res.redirect(routes.index)
      .catch (err) ->
        logger.error "error logging out user: #{err}"
        next(err)
}
