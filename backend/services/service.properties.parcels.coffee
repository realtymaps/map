db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
{geojson_query_bounds, tableName} = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'


transforms =
  bounds:
    transform: [
      validation.validators.string(minLength: 1)
      validation.validators.geohash
      validation.validators.array(minLength: 2)
    ]
    required: true


_tableName = tableName(Parcel)

module.exports =

  getBaseParcelData: (state, filters) -> Promise.try () ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      query = sqlHelpers.select(db.knex, 'parcel', false).from(sqlHelpers.tableName(Parcel))
      sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)
      logger.sql "#### parcel query: #{query}"
      query.then (data) ->
        geojson = 
          "type": "FeatureCollection"
          "features": _.uniq data, (row) ->
            row.rm_property_id
