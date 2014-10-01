logger = require '../config/logger'
###
  Iterate through all routeHandles and atatch a route to a handler
###
module.exports = (app, routesHandles) ->
  routesHandles.forEach (rh) ->
    logger.infoRoute "route: #{rh.route} intialized"

    if rh.route and not rh.handle
      throw new Error "route: #{rh.route} has no handle"
    if rh.handle and not rh.route
      throw new Error "handle: #{rh.handle} has no route"
    if not rh.handle or not rh.route
      throw new Error "no valid route -> handle"

    app.get rh.route, rh.handle
