frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
mod = require '../module.coffee'

mod.service 'rmapsUrlHelpers', ($location) ->
  #some routes do not follow the state->map symmetry (like admin), so
  #  we can use a "urls" mapping provided in the routes structure to use instead
  _useUrls = (routeStates) ->
    if !routeStates.urls?
      throw new Error("'urls' must be defined for the routes of this namespace.")
    return routeStates.urls

  getRoutes = () ->
    return if ///^\/admin///.test($location.path()) then _useUrls adminRoutes else frontendRoutes

  getRoutes: getRoutes
