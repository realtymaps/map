db = require('../config/dbs').properties
FilterSummary = require "../models/model.filterSummary"
Promise = require "bluebird"
logger = require '../config/logger'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'

validators = requestUtil.query.validators

statuses = ['for sale', 'recently sold', 'pending', 'not for sale', 'saved']

minMaxValidations =
  price: [validators.string(replace: [/[$,]/g, ""]), validators.float()]
  closePrice: [validators.string(replace: [/[$,]/g, ""]), validators.float()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.integer()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]
  
otherValidations =
  ownerName: validators.string(trim: true)
  hasOwner: [ validators.boolean() ]
  bounds: [
    validators.string(minLength: 1)
    validators.geohash.decode
    validators.array(minLength: 2)
    validators.geohash.transformToRawSQL(column: 'geom_polys_raw', coordSys: coordSys.UTM)
  ]
  status: validators.array(subValidation: [ validators.string(forceLowerCase: true),
                                            validators.choice(choices: statuses) ])



makeMinMaxes = (result, validators, name) ->
  result["#{name}Min"] = validators
  result["#{name}Max"] = validators

transforms = _.extend {}, otherValidations, _.transform(minMaxValidations, makeMinMaxes)


required =
  bounds: undefined
  status: []
  ownerName: ""


module.exports =

  getFilterSummary: (state, rawFilters, limit = 600) ->
    Promise.try () ->
      
      # note this is looking at the pre-transformed status filter
      if !rawFilters.status?.length
        #nothing to select, GTFO before we do any real work
        return []
        
      requestUtil.query.validateAndTransform(rawFilters, transforms, required)
      .then (filters) ->
  
        query = sqlHelpers.select(db.knex, "filter").from(sqlHelpers.tableName(FilterSummary))
        query.limit(limit) if limit
  
        # TODO: refactor geo validation so raw SQL generation happens in sqlHelpers and _whereRawSafe can be private
        sqlHelpers._whereRawSafe(query, filters.bounds)
  
        if filters.status.length < statuses.length
          sqlHelpers.whereIn(query, 'rm_status', filters.status)
  
        sqlHelpers.between(query, 'price', filters.priceMin, filters.priceMax)
        sqlHelpers.between(query, 'close_price', filters.closePriceMin, filters.closePriceMax)
        sqlHelpers.between(query, 'finished_sqft', filters.sqftMin, filters.sqftMax)
        sqlHelpers.between(query, 'acres', filters.acresMin, filters.acresMax)
  
        if filters.bedsMin
          query.where("bedrooms", '>=', filters.bedsMin)
  
        if filters.bathsMin
          query.where("baths_full", '>=', filters.bathsMin)
  
        if filters.hasOwner?
          # only checking owner_name here and now owner_name2 because we do normalization in the property summary
          # table that ensures we never have owner_name2 if we don't have owner_name -- therefore checking
          # only owner_name does the same thing and creates a more efficient query
          if filters.hasOwner
            query.whereNotNull('owner_name')
          else
            query.whereNull('owner_name')
  
        if filters.ownerName
          # need to avoid any characters that have special meanings in regexes
          # then split on whitespace and commas to get chunks to search for
          patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\s]/), (result, chunk) ->
            if !chunk
              return
            # make dashes and apostraphes optional, can be missing or replaced with a space in the name text
            # since this is after the split, a space here will be an actual part of the search
            result.push chunk.replace(/(['-])/g, "[$1 ]?")
          sqlHelpers.allPatternsInAnyColumn(query, patterns, ['owner_name', 'owner_name2'])
  
        if filters.listedDaysMin
          sqlHelpers.ageOrDaysFromStartToNow(query, 'listing_age_days', 'close_date', ">=", filters.listedDaysMin)
        if filters.listedDaysMax
          sqlHelpers.ageOrDaysFromStartToNow(query, 'listing_age_days', 'close_date', "<=", filters.listedDaysMax)
                    
        #logger.sql query.toString()
        return query
    .then (filteredProperties) ->
      if !filteredProperties?.length
        return []
      # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
      return _.uniq filteredProperties, (row) ->
        row.rm_property_id
    .then (filteredProperties) ->
      return filteredProperties if !state?.properties_selected || _.keys(state.properties_selected).length == 0
      
      # joining saved props to the filter data for properties that passed the filters, keeping track of which
      # ones hit so we can do further processing on the others
      matchingSavedProps = {}
      filteredProperties.forEach (row) ->
        maybeProp = state.properties_selected[row.rm_property_id]
        if maybeProp
          row.savedDetails = maybeProp
          row.passedFilters = true
          matchingSavedProps[row.rm_property_id] = true
      
      # now get data for any other saved properties and join saved props to them too
      missingProperties = _.filter _.keys(state.properties_selected), (rm_property_id) ->
        !matchingSavedProps[rm_property_id]
      if missingProperties.length == 0
        # shortcut out if we've handled them all
        return filteredProperties
      query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
      query.limit(limit) if limit
      sqlHelpers.whereIn(query, 'rm_property_id', missingProperties)
      query.then (savedProperties) ->
        savedProperties.forEach (row) ->
          row.savedDetails = state.properties_selected[row.rm_property_id]
          row.passedFilters = false
        return filteredProperties.concat(savedProperties)


  getSinglePropertySummary: (rm_property_id) -> Promise.try () ->
    query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
    query.where(rm_property_id: rm_property_id)
    query.limit(1) # TODO: if there are multiple, we just grab one... revisit once we deal with multi-untit parcels
    query.then (data) ->
      return data?[0]
