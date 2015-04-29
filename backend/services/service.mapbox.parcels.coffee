{properties, pg} = require('../config/dbs')
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
{geojson_query_bounds_non_exec, tableName} = require './../utils/util.sql.helpers.coffee'
{PROPERTY_DB} = require '../config/config'
JSONStream = require 'JSONStream'
mapboxUpload = require '../utils/util.mapbox'
fs = require 'fs'
combine = require 'stream-combiner'
through = require 'through'
split = require 'split'

transforms =
  bounds:
    transform: [
      validation.validators.string(minLength: 1)
      validation.validators.geohash
      validation.validators.array(minLength: 2)
    ]
    required: true


_tableName = tableName(Parcel)

_formatJSONStream = (stream) ->
    current = null

    write = (line, ignored, next) ->
        if (line.length == 0)
          return next()
        logger.debug line
        row = JSON.parse(line)

        if (row.name == 'FeatureCollection')
          if (current)
              this.push(JSON.stringify(current) + '\n')
          current = type: row.name, features: []

        else if (row.type == 'Feature')
          delete row.geom_polys_raw
          delete row.geom_point_raw
          row.properties = {}
          ['rm_property_id','street_address_num','geom_point_json'].forEach (prop) ->
            row.properties[prop] = row[prop]
            delete row[prop]
          current.features.push(row);
        next()

    end =  (next) ->
        if (current)
            this.push(JSON.stringify(current) + '\n')
        next()

    grouper = through(write, end)
    combine(stream, split(), grouper)

_uploadParcelByBounds = (bounds) -> Promise.try ->
  strQuery = geojson_query_bounds_non_exec(properties, _tableName,
    'geom_polys_json', 'geom_polys_raw', bounds).toString()

  #writeStream for manual testing
  writeStream = fs.createWriteStream './output.json'
  stream = properties.knex.raw(strQuery)
  .stream()
  .pipe(JSONStream.stringify())
  .pipe(JSONStream.parse('*.geojson_query_exec'))
  .pipe(JSONStream.stringify())

  # stream = _formatJSONStream(stream)
  #.pipe(process.stdout)
  .pipe(writeStream)

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
          mapboxUpload.uploadStreamPromise(mapId, stream, byteLen)
      )

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      _uploadParcelByBounds(filters.bounds)

  #for task usage
  uploadParcelByBounds: _uploadParcelByBounds
