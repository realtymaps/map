Promise = require 'bluebird'

userHandles = require './handles/handle.user'
backendRoutes = require '../../common/config/routes.backend.coffee'
bindRoutes = require '../utils/util.bindRoutesToHandles'

httpStatus = require '../../common/utils/httpStatus'



handles = [
  { route: backendRoutes.login, handle: userHandles.doLogin, method: 'post' }
  # JWI: for some reason, my debug output seems to indicate the logout route is getting called twice for every logout.
  # I have no idea why that is, but the second time it seems the user is already logged out.  Strange.
  { route: backendRoutes.logout, handle: userHandles.doLogout }
  { route: backendRoutes.identity, handle: userHandles.getIdentity }
  { route: backendRoutes.updateState, handle: userHandles.updateUserState, method: 'post' }
]

module.exports = (app) ->
  bindRoutes app, handles
