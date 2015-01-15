db = require('../config/dbs').properties
FilterSummary = require "../models/model.filterSummary"
Promise = require "bluebird"
logger = require '../config/logger'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'
dataPropertyUtil = require '../utils/util.data.properties.coffee'

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

  getFilterSummary: (state, rawFilters, limit = 600) -> Promise.try () ->
    
    # note this is looking at the pre-transformed status filter
    if !rawFilters.status?.length && (!state?.properties_selected || _.keys(state.properties_selected).length == 0)
      #nothing to select, bail before we do any real work
      return []
      
    requestUtil.query.validateAndTransform(rawFilters, transforms, required)
    .then (filters) ->

      query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
      query.limit(limit) if limit

      # TODO: refactor geo validation so raw SQL generation happens in sqlHelpers and _whereRawSafe can be private
      sqlHelpers._whereRawSafe(query, filters.bounds)
      
      query.where () ->

        if state?.properties_selected && _.keys(state.properties_selected).length > 0
          #Should we return saved properties that have isSaved false?
          #Main reason in asking is because a property is still saved if it has notes and isSaved is false.
          #We should consider removing isSaved and just consider it saved if it has notes. (not sure about this)
          #The main reason on having it around is because if you come back to it later you still
          #have notes and history about a prop (but you may not always want it highlighted on the map)
          sqlHelpers.whereIn(@, 'rm_property_id', _.keys(state.properties_selected))

        # if there are no statuses selected, then GTFO without any other querying for performance
        if filters.status.length == 0
          return

        # apply all other filters
        @.orWhere () ->
    
          if filters.status.length < statuses.length
            sqlHelpers.whereIn(@, 'rm_status', filters.status)
    
          sqlHelpers.between(@, 'price', filters.priceMin, filters.priceMax)
          sqlHelpers.between(@, 'close_price', filters.closePriceMin, filters.closePriceMax)
          sqlHelpers.between(@, 'finished_sqft', filters.sqftMin, filters.sqftMax)
          sqlHelpers.between(@, 'acres', filters.acresMin, filters.acresMax)
    
          if filters.bedsMin
            @.where("bedrooms", '>=', filters.bedsMin)
    
          if filters.bathsMin
            @.where("baths_full", '>=', filters.bathsMin)
    
          if filters.hasOwner?
            if filters.hasOwner
              @.where ->
                @whereNotNull('owner_name')
                @orWhereNotNull('owner_name2')
            else
              @.where ->
                @whereNull('owner_name')
                @orWhereNull('owner_name2')
    
          if filters.ownerName
            # need to avoid any characters that have special meanings in regexes
            # then split on whitespace and commas to get chunks to search for
            patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\s]/), (result, chunk) ->
              if !chunk
                return
              # make dashes and apostraphes optional, can be missing or replaced with a space in the name text
              # since this is after the split, a space here will be an actual part of the search
              result.push chunk.replace(/(['-])/g, "[$1 ]?")
            sqlHelpers.allPatternsInAnyColumn(@, patterns, ['owner_name', 'owner_name2'])
    
          if filters.listedDaysMin?
            sqlHelpers.daysGreaterThan(@, filters.listedDaysMin)
          if filters.listedDaysMax?
            sqlHelpers.daysLessThan(@, filters.listedDaysMax)
                  
      #logger.sql query.toString()
      return query
    .then (data) ->
      if !data
        return []
      # currently we have multiple records in our DB with the same poly...  this is a temporary fix to avoid the issue
      data = _.uniq data, (row) ->
        row.rm_property_id

      dataPropertyUtil.joinSavedProperties(state, data)
      return data

  getSinglePropertySummary: (rm_property_id) -> Promise.try () ->
    query = db.knex.select().from(sqlHelpers.tableName(FilterSummary))
    query.where(rm_property_id: rm_property_id)
    query.limit(1) # TODO: if there are multiple, we just grab one... revisit once we deal with multi-unti parcels
    query.then (data) ->
      return data?[0]
