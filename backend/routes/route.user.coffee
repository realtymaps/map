Promise = require 'bluebird'
querystring = require 'querystring'

auth = require '../config/auth'
logger = require '../config/logger'
config = require '../config/config'

userService = require '../services/service.user'
permissionsService = require '../services/service.permissions'

routes = require '../../common/config/routes'

doLoginRedirect = (req, res) -> Promise.try () ->
  if req.query.next
    return res.redirect(req.query.next)
  else
    return res.redirect(config.DEFAULT_LANDING_URL)

checkLogin = (req, res, next) -> Promise.try () ->
  logger.debug "checking for already logged-in user"
  if not req.user then return next()
  logger.debug "existing session found for username: #{req.user.username}"
  return doLoginRedirect(req, res)

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
      logger.debug "user logged in: #{user.username}"
      req.session.userid = user.id
      logger.debug "trying to set permissions on session for user: #{user.username}"
      return permissionsService.getPermissionsForUserId(user.id)
      .then (permissionsHash) ->
        logger.debug "permissions loaded on session for user: #{user.username}"
        req.session.permissions = permissionsHash
        return doLoginRedirect(req, res)
  .catch (err) ->
    logger.error "unexpected error during doLogin(): #{err}"
    next(err)


module.exports = (app) ->

  # if they're logged in already, redirect them to a landing page, else
  # serve this login form
  logger.infoRoute 'route.user.logIn (GET)', routes.logIn
  app.get routes.logIn, checkLogin, (req, res, next) -> Promise.try () ->
    # TODO: fix this to be the for-real way we display the login page
    return res.sendFile config.FRONTEND_ASSETS_PATH+"/login-form-test.html", (err) ->
      if (err)
        logger.error "error encountered while serving login page: #{err}"
        next(err)

  # if they're logged in already, redirect them to a landing page, else
  # process their post and try to log them in
  logger.infoRoute 'route.user.logIn (POST)', routes.logIn
  app.post routes.logIn, checkLogin, doLogin

  # we don't require you to be logged in to hit the logout button; that could
  # be confusing for users with a session that has been killed for one reason
  # or another (they would click logout and are then asked to login, if they
  # do then they are logged out...)
  # JWI: for some reason, my debug output seems to indicate this route is
  # getting called twice for every logout.  I have no idea why that is, but
  # the second time it seems the user is already logged out.  Strange.
  logger.infoRoute 'route.user.logOut (GET)', routes.logOut
  app.get routes.logOut, (req, res, next) -> Promise.try () ->
    logger.debug "attempting to log user out: #{req.user.username}"
    req.session.destroyAsync()
    .then () ->
      res.redirect(config.LOGOUT_URL)
    .catch (err) ->
      logger.error "error logging out user: #{err}"
      next(err)
