parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
{CARTODB} = require '../config/config'
cartodbUpload = require 'cartodb-upload'

JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
mapboxUpload = require '../utils/util.mapbox'
fs = require 'fs'

_upload = (stream, fileName) -> Promise.try ->
  # writeStream = fs.createWriteStream './output.json'
  filteredStream =
    stream.pipe(geoJsonFormatter())

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

_fipsCodeQuery = (fipsCode, limit) ->
  query = parcelSvc.getBaseParcelQuery()
  .where(fips_code:fipsCode)

  if limit
    query.limit(limit)
  # logger.debug query.toString()
  query

_parcel =
  upload: (fipsCode) ->
    _upload _fipsCodeQuery(fipsCode).stream(), 'parcels-' + fipsCode

  #initiates cartodb to synchronize (callback to us for a file)
  synchronize: (fipsCode) ->
    #need to add synchronize API to cartodb-upload

  getByFipsCode: (fileName, limit) ->
    #maybe parse file name for fipsCode?
    _fipsCodeQuery(fileName, limit)

module.exports =

  parcel: _parcel
  restful:
    getByFipsCode: (opts) ->
      # logger.debug(opts,true)
      if !opts or !opts.api_key? or opts.api_key != CARTODB.API_KEY_TO_US
        throw 'UNAUTHORIZED'
      if !opts.fipscode?
        throw 'BADREQUEST'
      limit = opts.limit || undefined
      _parcel.getByFipsCode(opts.fipscode, limit)
    uploadParcel: (state, filters) -> Promise.try ->
      _parcel.uploadParcel(filters.fips_code)
