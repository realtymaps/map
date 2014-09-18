Promise = require 'bluebird'

logger = require '../config/logger'
config = require '../config/config'
userUtils = require '../routeUtils/userUtils'
routes = require '../../common/config/routes'



module.exports = (app) ->

  # if they're logged in already, redirect them to a landing page, else
  # serve this login form
  logger.infoRoute 'route.user.logIn (GET)', routes.logIn
  app.get routes.logIn, userUtils.checkLogin, (req, res, next) -> Promise.try () ->
    # TODO: fix this to be the for-real way we display the login page
    return res.sendFile config.FRONTEND_ASSETS_PATH+"/login-form-test.html", (err) ->
      if (err)
        logger.error "error encountered while serving login page: #{err}"
        next(err)

  # if they're logged in already, redirect them to a landing page, else
  # process their post and try to log them in
  logger.infoRoute 'route.user.logIn (POST)', routes.logIn
  app.post routes.logIn, userUtils.checkLogin, userUtils.doLogin

  # we don't require you to be logged in to hit the logout button; that could
  # be confusing for users with a session that has been killed for one reason
  # or another (they would click logout and are then asked to login, if they
  # do then they are logged out...)
  # JWI: for some reason, my debug output seems to indicate this route is
  # getting called twice for every logout.  I have no idea why that is, but
  # the second time it seems the user is already logged out.  Strange.
  logger.infoRoute 'route.user.logOut (GET)', routes.logOut
  app.get routes.logOut, userUtils.doLogout
