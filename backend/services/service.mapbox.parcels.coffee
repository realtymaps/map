db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
{geojson_query_bounds, tableName} = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
upload = Promise.promisifyAll require('mapbox-upload')
{MAPBOX}= require '../config/config'
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
  geojsonStream = geojsonStream.pipe(JSONStream.stringify)#might not be needed
  Promise.try ->
    loader = upload
      stream: geojsonStream
      length: length
      account: MAPBOX.ACCOUNT
      accesstoken: MAPBOX.API_KEY
      mapid: mapId

    progress.on 'error', (err) ->
      if (err) throw err

    loader.onceAsync('finished')
    .then ->
      geojsonStream

_uploadParcelByBounds = (bounds) ->
  strQuery = geojson_query_bounds(db, _tableName, 'geom_polys_json',
    'geom_polys_raw', bounds).toString()

  new Promise (resolve, reject) ->
    pg.connect (err, client, done) ->
      reject(err) if err
      query = new QueryStream(strQuery)
      stream = client.query(query)
      #release the client when the stream is finished
      stream.on('end', done)

      resolve Promise.all _.map MAPBOX.MAPS, (mapId) ->
        _uploadStream(mapId, stream)

module.exports =

  #for webservice endpoint
  uploadParcel: (state, filters) -> Promise.try () ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      _uploadParcelByBounds(filters.bounds)

  #for task usage
  uploadParcelByBounds: _uploadParcelByBounds
