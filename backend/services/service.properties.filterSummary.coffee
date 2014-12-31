db = require('../config/dbs').properties
FilterSummary = require "../models/model.filterSummary"
Promise = require "bluebird"
logger = require '../config/logger'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'

validators = requestUtil.query.validators

statuses = ['for sale', 'recently sold', 'pending', 'not for sale']

transforms = 
  bounds: [
    validators.string(minLength: 1)
    validators.geohash.decode
    validators.array(minLength: 2)
    validators.geohash.transformToRawSQL(column: 'geom_polys_raw', coordSys: coordSys.UTM)
  ]
  status:   validators.array(subValidation: [ validators.string(forceLowerCase: true), validators.choice(choices: statuses) ])
  priceMin: [ validators.string(replace: [/[$,]/g, ""]), validators.float() ]
  priceMax: [ validators.string(replace: [/[$,]/g, ""]), validators.float() ]
  bedsMin:  validators.integer()
  bathsMin: validators.integer()
  acresMin: validators.float()
  acresMax: validators.float()
  sqftMin:  [ validators.string(replace: [/,/g, ""]), validators.integer() ]
  sqftMax:  [ validators.string(replace: [/,/g, ""]), validators.integer() ]
  # other fields we could have:
  #   close date (to remove the hardcoded "recently sold" logic and allow specification by time window)
  #   owner name
  #   bedsMax
  #   bathsMax
  #   bathsHalf[Min/Max]
  #   property type

required =
  bounds: undefined
  status: []

module.exports = 
  
  getFilterSummary: (filters, limit = 600) -> Promise.try () ->
    requestUtil.query.validateAndTransform(filters, transforms, required)
    .then (filters) ->

      # we allow the query to get here without error so we can save the filter state, but if there are no valid
      # statuses specified, we want to shortcut out with no results
      if filters.status.length == 0
        return []

      query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
      query.whereRaw(filters.bounds.sql, filters.bounds.bindings)
      
      if filters.status.length == 1
        query.where('rm_status', filters.status[0])
      else if filters.status.length < statuses.length
        query.whereIn('rm_status', filters.status)

      sqlHelpers.between(query, 'price', filters.priceMin, filters.priceMax)
      sqlHelpers.between(query, 'finished_sqft', filters.sqftMin, filters.sqftMax)
      sqlHelpers.between(query, 'acres', filters.acresMin, filters.acresMax)
      
      if filters.bedsMin?
        query.where("bedrooms", '>=', filters.bedsMin)
      
      if filters.bathsMin?
        query.where("baths_full", '>=', filters.bathsMin)

      query.limit(limit) if limit

      query.then (data) ->
        data = data||[]
        # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
        data = _.uniq data, (row) ->
          row.rm_property_id
        data
