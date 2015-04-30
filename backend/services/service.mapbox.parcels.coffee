parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
{MAPBOX} = require '../config/config'

JSONStream = require 'JSONStream'
featureCollectionWrapStream = require '../utils/util.featureCollectionWrapStream'
mapboxUpload = require '../utils/util.mapbox'
fs = require 'fs'

_uploadParcelByQuery = (stream) -> Promise.try ->
  writeStream = fs.createWriteStream './output.json'
  filteredStream =
    stream.pipe(featureCollectionWrapStream())

  # filteredStream.pipe(process.stdout) #uncomment to send to console
  # filteredStream.pipe(writeStream) #uncomment to write file

  #comment below out to not send to mapbox
  byteLen = 0

  filteredStream.on 'data', (chunk) ->
    # logger.debug (new Buffer(chunk)).toString('utf-8')
    byteLen += chunk.length

  new Promise (resolve, reject) ->
    filteredStream.on 'error', reject
    filteredStream.on 'end', ->
      logger.debug "stream length: #{byteLen}"
      logger.debug 'done processing stream'

      resolve Promise.all _.map MAPBOX.MAPS, (mapId) ->
        mapboxUpload.uploadStreamPromise(mapId, filteredStream, byteLen)

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try ->
    parcelSvc.getBaseParcelDataUnwrapped(state,filters, doStream = true)
    .then (stream) ->
      _uploadParcelByQuery stream
  #for task usage
  uploadParcelByQuery: _uploadParcelByQuery
