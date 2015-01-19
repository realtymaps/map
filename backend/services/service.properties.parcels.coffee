db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
geohashHelper = require '../utils/validation/util.validation.geohash'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'

validators = requestUtil.query.validators

transforms =
  bounds: [
    validators.string(minLength: 1)
    validators.geohash.decode
    validators.array(minLength: 0)
    validators.geohash.transformToRawSQL(column: 'geom_polys_raw', coordSys: coordSys.UTM)
  ]

required =
  bounds: undefined


module.exports =

  getBaseParcelData: (state, filters) -> Promise.try () ->
    requestUtil.query.validateAndTransform(filters, transforms, required)
    .then (filters) ->

      if filters.bounds == "dummy"
        return []

      query = sqlHelpers.select(db.knex, '*', false).from(sqlHelpers.tableName(Parcel))
      sqlHelpers._whereRawSafe(query, filters.bounds)
      #logger.sql query.toString()      
      return query

    .then (data) ->
      data = data||[]
      # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
      return _.uniq data, (row) ->
        row.rm_property_id
