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

minMaxValiations = {
  price: [validators.string(replace: [/[$,]/g, ""]), validators.float()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.integer()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]
}
otherValidations = {
  bounds: [
    validators.string(minLength: 1)
    validators.geohash.decode
    validators.array(minLength: 2)
    validators.geohash.transformToRawSQL(column: 'geom_polys_raw', coordSys: coordSys.UTM)
  ]
  status: validators.array(subValidation: [ validators.string(forceLowerCase: true),
                                            validators.choice(choices: statuses) ])
  ownerName: validators.string(trim: true)
}


makeMinMaxes = (result, validators, name) ->
  result["#{name}Min"] = validators
  result["#{name}Max"] = validators

transforms = _.extend {}, otherValidations, _.transform(minMaxValiations, makeMinMaxes)


required =
  bounds: undefined
  status: []
  ownerName: ""


module.exports =

  getFilterSummary: (state, filters, limit = 600) -> Promise.try () ->
    requestUtil.query.validateAndTransform(filters, transforms, required)
    .then (filters) ->

      # we allow the query to get here without error so we can save the filter state, but if there are no valid
      # statuses specified, we want to shortcut out with no results
      if filters.status.length == 0
        return []

      query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
      # TODO: refactor geo validation so raw SQL generation happens in sqlHelpers and _whereRawSafe can be private
      sqlHelpers._whereRawSafe(query, filters.bounds)

      if filters.status.length == 1
        query.where('rm_status', filters.status[0])
      else if filters.status.length < statuses.length
        query.whereIn('rm_status', filters.status)

      sqlHelpers.between(query, 'price', filters.priceMin, filters.priceMax)
      sqlHelpers.between(query, 'finished_sqft', filters.sqftMin, filters.sqftMax)
      sqlHelpers.between(query, 'acres', filters.acresMin, filters.acresMax)

      if filters.bedsMin
        query.where("bedrooms", '>=', filters.bedsMin)

      if filters.bathsMin
        query.where("baths_full", '>=', filters.bathsMin)

      if filters.ownerName
        # need to avoid any characters that have special meanings in regexes
        # then split on whitespace and commas to get chunks to search for
        patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\w]/), (result, chunk) ->
          if !chunk
            return
          # make dashes and apostraphes optional, can be missing or replaced with a space in the name text
          # since this is after the split, a space here will be an actual part of the search
          result.push chunk.replace(/(['-])/g, "[$1 ]?")
        sqlHelpers.allPatternsInAnyColumn(query, patterns, ['owner_name', 'owner_name2'])

      if filters.listedDaysMin?
        sqlHelpers.daysGreaterThan(query, filters.listedDaysMin)
      if filters.listedDaysMax?
        sqlHelpers.daysLessThan(query, filters.listedDaysMax)

      if state and state.properties_selected
        #Should we return saved properties that have isSaved false?
        #Main reason in asking is because a property is still saved if it has notes and isSaved is false.
        #We should consider removing isSaved and just consider it saved if it has notes. (not sure about this)
        #The main reason on having it around is because if you come back to it later you still
        #have notes and history about a prop (but you may not always want it highlighted on the map)
        query.orWhere ->
          sqlHelpers._whereRawSafe(@, filters.bounds)
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
