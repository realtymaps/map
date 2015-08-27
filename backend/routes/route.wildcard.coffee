config = require '../config/config'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
viewsRoute = require './route.views'

_staticAssets = [
  /\/assets\//
  /\/json\//
  /\/fonts\//
  /\/scripts\//
  /\/styles\//
]

module.exports =

  # this wildcard allows express to deal with any unknown api URL
  backend:
    method: 'all'
    order: 9998 # needs to be first
    handle: (req, res, next) ->
      next new ExpressResponse(alert: {msg: "Oops!  The API resource #{req.path} was not found.  Try reloading the page."}, httpStatus.NOT_FOUND)

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
      for key, regEx of _staticAssets
        if req.path.match regEx
          next new ExpressResponse(alert: {msg: "Oops!  The resource #{req.path} was not found.  Try reloading the page."}, httpStatus.NOT_FOUND)

      viewsRoute.rmap(req,res,next)
