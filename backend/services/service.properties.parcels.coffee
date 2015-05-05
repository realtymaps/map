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
      geojson = 
        "type": "FeatureCollection"
        "features": _.uniq data, (row) ->
          row.rm_property_id

