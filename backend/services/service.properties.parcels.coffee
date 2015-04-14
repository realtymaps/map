db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
geohashHelper = require '../utils/validation/util.validation.geohash'
requestUtil = require '../utils/util.http.request'
{geojson_query_bounds, tableName} = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'

validators = requestUtil.query.validators

transforms =
  bounds: [
    validators.string(minLength: 1)
    validators.geohash
    validators.array(minLength: 2)
  ]

required =
  bounds: undefined

_tableName = tableName(Parcel)

module.exports =

  getBaseParcelData: (state, filters) -> Promise.try () ->
    requestUtil.query.validateAndTransform(filters, transforms, required)
    .then (filters) ->
      query = geojson_query_bounds(db, _tableName, 'geom_polys_json', 'geom_polys_raw', filters.bounds)
      # logger.sql query.toString()
      query
