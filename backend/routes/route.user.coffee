Promise = require 'bluebird'

logger = require '../config/logger'
config = require '../config/config'
userUtils = require '../utils/util.user'
backendRoutes = require '../../common/config/routes.backend.coffee'

httpStatus = require '../../common/utils/httpStatus'



module.exports = (app) ->

  logger.infoRoute 'route.user.login (POST)', backendRoutes.login
  app.post backendRoutes.login, userUtils.doLogin

  # we don't require you to be logged in to hit the logout button; that could
  # be confusing for users with a session that has been killed for one reason
  # or another (they would click logout and are then asked to login, if they
  # do then they are logged out...)
  # JWI: for some reason, my debug output seems to indicate this route is
  # getting called twice for every logout.  I have no idea why that is, but
  # the second time it seems the user is already logged out.  Strange.
  logger.infoRoute 'route.user.logout (GET)', backendRoutes.logout
  app.get backendRoutes.logout, userUtils.doLogout
  
  logger.infoRoute 'route.user.identity', backendRoutes.identity
  app.get backendRoutes.identity, (req, res, next) ->
    if not req.user
      return res.json identity: null
    # here we should probaby return some things from the user's profile as well, such as name
    return res.json identity:
      permissions: req.session.permissions
      groups: req.session.groups
