###
  Iterate through all routeHandles and atatch a route to a handler
###
module.exports = (app, routesHandles) ->
  routesHandles.forEach (rh) ->
    logger.infoRoute "route: #{rh.route} intialized"

    app.get rh.route, rh.handle
