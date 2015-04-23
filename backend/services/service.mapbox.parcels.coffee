db = require('../config/dbs')
{properties} = db
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
{geojson_query_bounds_non_exec, tableName} = require './../utils/util.sql.helpers.coffee'
upload = require('mapbox-upload')
{MAPBOX}= require '../config/config'
JSONStream = require 'JSONStream'
QueryStream = require 'pg-query-stream'

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

_uploadParcelByBounds = (bounds) ->
  strQuery = geojson_query_bounds_non_exec(properties, _tableName, 'geom_polys_json', 'geom_polys_raw', bounds).toString()
  logger.sql strQuery

  new Promise (resolve, reject) ->
    # logger.sql db.pg
    db.pg.connect (err, client, done) ->
      reject(err) if err
      qs = new QueryStream strQuery
      stream = client.query qs
      logger.sql 'pre stream'
      # logger.sql stream, true
      #release the client when the stream is finished
      stream.on('error', reject)
      stream.on 'end', ->
        logger.sql 'stream is fucking done'
        done()
      logger.sql 'past end'
      stream.pipe(process.stdout)
      # resolve Promise.all _.map MAPBOX.MAPS, (mapId) ->
      #   logger.sql mapId
      #   _uploadStream(mapId, stream)

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try () ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      _uploadParcelByBounds(filters.bounds)

  #for task usage
  uploadParcelByBounds: _uploadParcelByBounds
