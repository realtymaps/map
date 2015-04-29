parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'


JSONStream = require 'JSONStream'
{basicWrapStream, complexWrapStream} = require '../utils/util.featureCollectionWrapStream'
mapboxUpload = require '../utils/util.mapbox'
fs = require 'fs'


_uploadParcelByQuery = (stream) -> Promise.try ->
  # logger.sql stream
  writeStream = fs.createWriteStream './output.json'
  stream
  .pipe(JSONStream.stringify())
  # .pipe(basicWrapStream())
  .pipe(complexWrapStream())
  # .pipe(process.stdout)
  .pipe(writeStream)

  # byteLen = 0
  #
  # stream.on 'data', (chunk) ->
  #   logger.sql chunk
  #   byteLen += chunk.length
  #
  # new Promise (resolve, reject) ->
  #   stream.on 'error', reject
  #   stream.on 'end', ->
  #     logger.debug "stream length: #{byteLen}"
  #     logger.debug 'done processing stream'
  #     #stream.pipe(process.stdout) debug
  #     resolve(
  #       Promise.all _.map MAPBOX.MAPS, (mapId) ->
  #         logger.sql mapId
  #         mapboxUpload.uploadStreamPromise(mapId, stream, byteLen)
  #     )

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try ->
    parcelSvc.getBaseParcelDataUnwrapped(state,filters, doStream = true)
    .then (stream) ->
      _uploadParcelByQuery stream
  #for task usage
  uploadParcelByQuery: _uploadParcelByQuery
