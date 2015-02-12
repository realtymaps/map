db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
geohashHelper = require '../utils/validation/util.validation.geohash'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers.coffee'

validators = requestUtil.query.validators

transforms =
  bounds: [
    validators.string(minLength: 1)
    validators.geohash
    validators.array(minLength: 0)
  ]

required =
  bounds: undefined


module.exports =

  getBaseParcelData: (state, filters) -> Promise.try () ->
    requestUtil.query.validateAndTransform(filters, transforms, required)
    .then (filters) ->

      query = sqlHelpers.select(db.knex, 'parcel', false).from(sqlHelpers.tableName(Parcel))
      sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)
      
      #logger.sql query.toString()      
      return query

    .then (data) ->
      data = data||[]
      # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
      return _.uniq data, (row) ->
        row.rm_property_id
