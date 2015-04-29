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

_getBaseParcelDataUnwrapped = (state, filters, doStream = false) -> Promise.try () ->
  validation.validateAndTransform(filters, transforms)
  .then (filters) ->
    query = sqlHelpers.select(db.knex, 'parcel', false).from(sqlHelpers.tableName(Parcel))
    sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)
    ret = query
    ret = query.stream() if doStream
    ret

module.exports =

  getBaseParcelDataUnwrapped: _getBaseParcelDataUnwrapped
  # pseudo-new implementation
  getBaseParcelData: (state, filters) ->
    _getBaseParcelDataUnwrapped(state,filters)
    .then (data) ->
      return {"type": "FeatureCollection", "features": data}


  # old implementation:
  # getBaseParcelData: (state, filters) -> Promise.try () ->
  #   requestUtil.query.validateAndTransform(filters, transforms, required)
  #   .then (filters) ->

  #     query = sqlHelpers.select(db.knex, 'parcel', false).from(sqlHelpers.tableName(Parcel))
  #     sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)

  #     #logger.sql query.toString()
  #     return query

  #   .then (data) ->
  #     data = data||[]
  #     # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
  #     return _.uniq data, (row) ->
  #       row.rm_property_id
  #   .then (data) ->
  #     indexBy(data)

  # current implementation:
  # getBaseParcelData: (state, filters) -> Promise.try () ->
  #   validation.validateAndTransform(filters, transforms)
  #   .then (filters) ->
  #     query = geojson_query_bounds(db, _tableName, 'geom_polys_json', 'geom_polys_raw', filters.bounds)
  #     logger.debug "#### query: " + JSON.stringify(query)
  #     logger.sql query.toString()
  #     query
