db = require('../config/dbs').properties
FilterSummary = require "../models/model.filterSummary"
Promise = require "bluebird"
logger = require '../config/logger'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'
dataPropertyUtil = require '../utils/util.data.properties.coffee'

validators = requestUtil.query.validators

statuses = ['for sale', 'recently sold', 'pending', 'not for sale']


minMaxes = {}
[
  {name: 'price', validators: [validators.string(replace: [/[$,]/g, ""]), validators.float()]}
  {name: 'closePrice', validators: [validators.string(replace: [/[$,]/g, ""]), validators.float()]}
  {name: 'listedDays', validators: validators.integer()}
  {name: 'beds', validators: validators.integer()}
  {name: 'baths', validators: validators.integer()}
  {name: 'acres', validators: validators.float()}
  {name: 'sqft', validators: [ validators.string(replace: [/,/g, ""]), validators.integer() ]}
].forEach (f) ->
  ['Max', 'Min'].forEach (minMax) ->
    minMaxes[f.name + minMax] = f.validators

transforms =
  _.extend minMaxes,
    bounds: [
      validators.string(minLength: 1)
      validators.geohash.decode
      validators.array(minLength: 2)
      validators.geohash.transformToRawSQL(column: 'geom_polys_raw', coordSys: coordSys.UTM)
    ]
    status: validators.array(subValidation: [ validators.string(forceLowerCase: true),
      validators.choice(choices: statuses) ])
    hasOwner: [ validators.boolean() ]

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

  getFilterSummary: (state, filters, limit = 600) -> Promise.try () ->
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

      if filters.hasOwner?
        if filters.hasOwner
          query.whereNotNull('owner_name')
        else
          query.whereNull('owner_name')

      if filters.closePriceMin?
        sqlHelpers.between(query, 'close_price', filters.closePriceMin, filters.closePriceMax)

      if filters.listedDaysMin?
        query.whereRaw sqlHelpers.daysGreaterThan(filters.listedDaysMin)
      if filters.listedDaysMax?
        query.whereRaw sqlHelpers.daysLessThan(filters.listedDaysMax)

      if state and state.properties_selected
        #Should we return saved properties that have isSaved false?
        #Main reason in asking is because a property is still saved if it has notes and isSaved is false.
        #We should consider removing isSaved and just consider it saved if it has notes. (not sure about this)
        #The main reason on having it around is because if you come back to it later you still
        #have notes and history about a prop (but you may not always want it highlighted on the map)
        query.orWhere ->
          @whereRaw(filters.bounds.sql, filters.bounds.bindings)
          @where(rm_property_id: _.keys(state.properties_selected))
      query.limit(limit) if limit
      #logger.sql query.toString()

      query.then (data) ->
        data = data or []
        # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
        data = _.uniq data, (row) ->
          row.rm_property_id
        data = dataPropertyUtil.joinSavedProperties(state, data)
        return data

  getSinglePropertySummary: (rm_property_id) -> Promise.try () ->
    query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
    query.where(rm_property_id: rm_property_id)
    query.limit(1) # TODO: if there are multiple, we just grab one... revisit once we deal with multi-unti parcels
    query.then (data) ->
      return data?[0]
