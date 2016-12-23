# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:tiles")
# coffeelint: enable=check_scope
request = require('request')
cartodbConfig = require '../config/cartodb/cartodb'
httpStatus = require '../../common/utils/httpStatus'
_ = require 'lodash'
ExpressResponse = require '../utils/util.expressResponse'

getTiles = (mapName) ->
  (req, res, next) ->
    cartodbConfig()
    .then (carto) ->
      parcelMap = _.find(carto.MAPS, 'name', mapName)
      url = "https:#{carto.ROOT_URL}/map/#{parcelMap.mapId}/#{req.params.z}/#{req.params.x}/#{req.params.y}.png"
      logger.debug url

      headers =  {} #_.omit(req.headers, 'host')
      for k, v of headers
        logger.debug k, v

      request {
        url
        encoding: null # ensures body will be a buffer
        headers
      }, (err, response, body) ->
        try
          if !err
            if response.statusCode < 400
              for k, v of response.headers
                if k != 'content-length'
                  logger.debug k, v
                  res.setHeader(k, v)
              res.write(body)
              res.end()
              return
          throw new Error("Could not load map tile")
        catch err
          return next new ExpressResponse(alert: {msg: "Could not load map tile"}, {status: response?.statusCode || httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})

    .catch (err) ->
      logger.debug err
      next new ExpressResponse(alert: {msg: "Could not load map tile"}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})

module.exports =
  parcels:
    method: 'get'
    handle: getTiles('parcels')

  parcelsAddresses:
    method: 'get'
    handle: getTiles('parcelsAddresses')
