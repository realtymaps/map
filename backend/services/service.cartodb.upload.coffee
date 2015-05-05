parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
{CARTODB} = require '../config/config'
cartodbUpload = require 'cartodb-upload'

JSONStream = require 'JSONStream'
featureCollectionWrapStream = require '../utils/util.featureCollectionWrapStream'
mapboxUpload = require '../utils/util.mapbox'
fs = require 'fs'

_upload = (stream, fileName) -> Promise.try ->
  # writeStream = fs.createWriteStream './output.json'
  filteredStream =
    stream.pipe(featureCollectionWrapStream())

  # filteredStream.pipe(process.stdout) #uncomment to send to console
  # filteredStream.pipe(writeStream) #uncomment to write file

  new Promise (resolve, reject) ->
    filteredStream.on 'error', reject
    filteredStream.on 'end', ->
      logger.debug "stream length: #{byteLen}"
      logger.debug 'done processing stream'

      resolve Promise.all _.map MAPBOX.MAPS, (mapId) ->
        cartodbUpload
          apiKey: CARTODB.API_KEY
          stream: filteredStream
          uploadFileName: fileName

_parcel =
  upload: (fipsCode) ->
    query = parcelSvc._getBaseParcelQuery()
    .where(fips:fipsCode)
    
    _upload query.stream(), 'parcels-' + fipsCode

module.exports =

  parcel: _parcel
  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try ->
    _parcel.uploadParcel
  #for task usage
