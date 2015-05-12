upload = require 'mapbox-upload'
{MAPBOX, PROPERTY_DB} = require '../config/config'
Promise = require "bluebird"
logger = require '../config/logger'

_uploadStreamPromise = (mapId, geojsonStream, length) ->
  # geojsonStream: string formatted stream
  # length: length
  new Promise (resolve, reject) ->
    logger.debug "pre-mapbox-upload"
    loader = upload
      stream: geojsonStream
      account: MAPBOX.ACCOUNT
      accesstoken: MAPBOX.UPLOAD_KEY
      mapid: mapId
      length: length

    loader.on 'error', (err) ->
      logger.error "mapbox-upload error: #{err}"
      reject(err)
    loader.on 'progress', (p) ->
        logger.debug p, true

    loader.once 'finished', ->
      logger.debug "done uploading to mapbox"
      resolve geojsonStream

module.exports =
  uploadStreamPromise: _uploadStreamPromise
