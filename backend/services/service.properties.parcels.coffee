db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'


transforms =
  bounds:
    transform: [
      validation.validators.string(minLength: 1)
      validation.validators.geohash
      validation.validators.array(minLength: 2)
    ]
    required: true

_tableName = sqlHelpers.tableName(Parcel)

_getBaseParcelQuery = ->
  sqlHelpers.select(db.knex, 'parcel', false)
  .from(_tableName)

_getBaseParcelQueryByBounds = (bounds) ->
  query = _getBaseParcelQuery()
  sqlHelpers.whereInBounds(query, 'geom_polys_raw', bounds)
  query

_getBaseParcelDataUnwrapped = (state, filters, doStream) -> Promise.try () ->
  validation.validateAndTransform(filters, transforms)
  .then (filters) ->
    query = _getBaseParcelQuery(filters.bounds)
    return query.stream() if doStream
    query

module.exports =
  getBaseParcelQuery: _getBaseParcelQuery
  getBaseParcelQueryByBounds: _getBaseParcelQueryByBounds
  getBaseParcelDataUnwrapped: _getBaseParcelDataUnwrapped
  # pseudo-new implementation
  getBaseParcelData: (state, filters) ->
    _getBaseParcelDataUnwrapped(state,filters)
    .then (data) ->
      geojson =
        "type": "FeatureCollection"
        "features": _.uniq data, (row) ->
          row.rm_property_id
