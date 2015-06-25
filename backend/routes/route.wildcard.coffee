config = require '../config/config'
ExpressResponse = require '../utils/util.expressResponse'
logger = require '../config/logger'
httpStatus = require '../../common/utils/httpStatus'
viewsRoute = require './route.views'


module.exports =

  # this wildcard allows express to deal with any unknown api URL
  backend: (req, res, next) ->
    next new ExpressResponse(alert: {msg: "Oops!  The API resource #{req.path} was not found.  Try reloading the page."}, httpStatus.NOT_FOUND)

  admin: (req, res, next) ->
    viewsRoute.admin(req,res,next)

  # this wildcard allows angular to deal with any URL that isn't an api URL
  frontend: (req, res, next) ->
    viewsRoute.rmap(req,res,next)
