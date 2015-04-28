{properties, pg} = require('../config/dbs')
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
{geojson_query_bounds_non_exec, tableName} = require './../utils/util.sql.helpers.coffee'
upload = require 'mapbox-upload'
{MAPBOX,PROPERTY_DB}= require '../config/config'
JSONStream = require 'JSONStream'

transforms =
  bounds:
    transform: [
      validation.validators.string(minLength: 1)
      validation.validators.geohash
      validation.validators.array(minLength: 2)
    ]
    required: true


_tableName = tableName(Parcel)

_uploadStream = (mapId, geojsonStream, length) ->
  # geojsonStream = geojsonStream.pipe(JSONStream.stringify)#might not be needed
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

_uploadParcelByBounds = (bounds) -> Promise.try ->
  strQuery = geojson_query_bounds_non_exec(properties, _tableName,
    'geom_polys_json', 'geom_polys_raw', bounds).toString()
  # strQuery = 'select * from parcels limit 10'
  # logger.sql strQuery
  # logger.sql _.keys db.properties.knex
  stream = properties.knex.raw(strQuery)
  .stream().pipe(JSONStream.stringify())

  byteLen = 0

  stream.on 'data', (chunk) ->
    byteLen += chunk.length

  new Promise (resolve, reject) ->
    stream.on 'error', reject
    stream.on 'end', ->
      logger.debug "stream length: #{byteLen}"
      logger.debug 'done processing stream'
      #stream.pipe(process.stdout) debug
      resolve(
        Promise.all _.map MAPBOX.MAPS, (mapId) ->
          logger.sql mapId
          _uploadStream(mapId, stream, byteLen)
      )

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      _uploadParcelByBounds(filters.bounds)

  #for task usage
  uploadParcelByBounds: _uploadParcelByBounds
