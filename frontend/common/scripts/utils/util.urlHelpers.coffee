frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

#some routes do not follow the state->map symmetry (like admin), so 
#  we can use a "urls" mapping provided in the routes structure to use instead
useUrls = (routeStates) ->
  if !routeStates.urls?
    throw new Error("'urls' must be defined for the routes of this namespace.")
  return routeStates.urls

getRoutes = (loc) ->
  return if ///^\/admin///.test(loc.path()) then useUrls adminRoutes else frontendRoutes

module.exports =
  useUrls: useUrls
  getRoutes: getRoutes