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
    loader = upload
      stream: geojsonStream
      account: MAPBOX.ACCOUNT
      accesstoken: MAPBOX.API_KEY
      mapid: mapId

    loader.on 'error', reject

    loader.once 'finished', ->
      resolve geojsonStream

_uploadParcelByBounds = (bounds) -> Promise.try ->
  strQuery = geojson_query_bounds_non_exec(properties, _tableName,
    'geom_polys_json', 'geom_polys_raw', bounds).toString()
  # strQuery = 'select * from parcels limit 10'
  # logger.sql strQuery
  # logger.sql _.keys db.properties.knex
  stream = properties.knex.raw(strQuery)
  .stream().pipe(JSONStream.stringify())

  stream.on 'end', ->
    logger.debug 'done processing stream'
  #stream.pipe(process.stdout) debug
  Promise.all _.map MAPBOX.MAPS, (mapId) ->
    logger.sql mapId
    _uploadStream(mapId, stream)

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      _uploadParcelByBounds(filters.bounds)

  #for task usage
  uploadParcelByBounds: _uploadParcelByBounds
