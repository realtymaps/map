# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:tiles")
# coffeelint: enable=check_scope
config = require '../config/config'
request = require('request')
cartodbConfig = require '../config/cartodb/cartodb'
httpStatus = require '../../common/utils/httpStatus'
_ = require 'lodash'
ExpressResponse = require '../utils/util.expressResponse'

getTiles = (mapName) ->
  (req, res, next) ->

    _onError = (err) ->
      logger.debug err
      next new ExpressResponse(alert: {msg: "Could not load map tile"}, {status: err.statusCode || httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})

    cartodbConfig()
    .then (carto) ->
      parcelMap = _.find(carto.MAPS, 'name', mapName)
      url = "https:#{carto.ROOT_URL}/map/#{parcelMap.mapId}/#{req.params.z}/#{req.params.x}/#{req.params.y}.png"
      logger.debug -> url

      stream = request({
        url
        encoding: null # ensures body will be a buffer
      })
      .on('error', _onError)
      .on('response', (response) ->
        try
          logger.debug "response #{response.statusCode}"
          if response.statusCode < 400
            res.status(response.statusCode)
            stream.pipe(res)
            return
          throw new Error("Could not load map tile")
        catch err
          err.statusCode = response?.statusCode
          _onError(err)
      )

      stream.pipefilter = (response, res) ->
        for k of response.headers
          logger.debug "pipfiltering", k
          res.removeHeader(k)
        res.setHeader('cache-control', "public, max-age=#{config.FRONTEND_ASSETS.MAX_AGE_SEC}")
        res.setHeader('content-type', response.headers['content-type'] || 'image/png')

    .catch _onError

module.exports =
  parcels:
    method: 'get'
    handle: getTiles('parcels')

  parcelsAddresses:
    method: 'get'
    handle: getTiles('parcelsAddresses')
