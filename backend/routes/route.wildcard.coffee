ExpressResponse = require '../utils/util.expressResponse'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:wildcard")
# coffeelint: enable=check_scope
httpStatus = require '../../common/utils/httpStatus'
viewsRoute = require './route.views'

module.exports =

  # this wildcard allows express to deal with any unknown api URL
  backend:
    method: 'all'
    order: 9998 # needs to be first
    handle: (req, res, next) ->
      next new ExpressResponse(alert: {msg: "Oops!  The API resource #{req.path} was not found.  Try reloading the page."}, {status: httpStatus.NOT_FOUND})

  admin:
    method: 'all'
    order: 9999 # needs to be next to last
    handle: (req, res, next) ->
      viewsRoute.admin(req,res,next)

  # this wildcard allows angular to deal with any URL that isn't an api URL
  frontend:
    method: 'all'
    order: 10000 # needs to be last
    handle: (req, res, next) ->
      # if the request had a file-ish format (with a '.' in it), then return a 404 -- it would have been caught by the
      # static serving middleware if we had the file
      if req.path.indexOf('.') != -1
        return next new ExpressResponse("Oops!  The resource #{req.path} was not found.  Try reloading the page, or try again later.", {status: httpStatus.NOT_FOUND})
      viewsRoute.rmap(req,res,next)
