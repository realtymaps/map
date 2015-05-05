db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
geohashHelper = require '../utils/validation/util.validation.geohash'
validation = require '../utils/util.validation'
{select, tableName, whereInBounds} = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'


validators = validation.validators

transforms =
  bounds:
    transform: [
      validators.string(minLength: 1)
      validators.geohash
      validators.array(minLength: 2)
    ]
    required: true


module.exports =

  get: (state, filters) -> Promise.try () ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->

      query = select(db.knex, 'parcel', false)
      .from(tableName(Parcel))
      whereInBounds(query, 'geom_polys_raw', filters.bounds)
      # logger.sql query.toString()
      return query

    .then (data) ->
      # logger.sql data, true
      data = data or []
      # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
      return _.uniq data, (row) ->
        row.rm_property_id
    .then (data) ->
      obj = {}
      #hack for unique markerid on address markers (NEED TO FIX IN LEAFLET Marker Directive)
      data.forEach (val) ->
        val.type = val.geom_point_json.type
        val.coordinates = val.geom_point_json.coordinates
        obj['addr' + val.rm_property_id] = val
      # logger.debug obj, true
      obj
