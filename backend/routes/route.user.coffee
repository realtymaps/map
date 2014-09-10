auth = require '../config/auth'
logger = require '../config/logger'
config = require '../config/config'

Promise = require 'bluebird'


module.exports = (app) ->

  app.get '/login', auth.checkLogin(), (req, res, next) -> Promise.try () ->
    # TODO: fix this to be the for-real way we display the login page
    return res.sendFile config.FRONTEND_ASSETS_PATH+"/login-form-test.html", (err) ->
      if (err)
        logger.error "error encountered while serving login page: #{err}"
        next(err)

  app.post '/login', auth.doLogin()

  # we don't require you to be logged in to hit the logout button; that could
  # be confusing for users with a session that has been killed for one reason
  # or another (they would click logout and are then asked to login, if they
  # do then they are logged out...)
  app.get '/logout', auth.allowAll(), (req, res, next) -> Promise.try () ->
    # only call req.logout() if it exists, i.e. if the user is logged in 
    logger.debug "attempting to log user out: #{req.user.username}"
    req.session.destroyAsync()
      .then () ->
        res.redirect(config.LOGOUT_URL)
      .catch (err) ->
        logger.error "error logging out user: #{err}"
        next(err)

###
  app.post '/signup', auth.none, (req, res) ->
  
###
