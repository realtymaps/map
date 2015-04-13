db = require('../config/dbs').properties
PropertyDetails = require "../models/model.propertyDetails"
Promise = require "bluebird"
logger = require '../config/logger'
config = require '../config/config'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers'
filterStatuses = require '../enums/filterStatuses'


validators = requestUtil.query.validators

statuses = filterStatuses.keys
filterStatusesEnum =  filterStatuses.enum

minMaxValidations =
  price: [validators.string(replace: [/[$,]/g, ""]), validators.float()]
  closePrice: [validators.string(replace: [/[$,]/g, ""]), validators.float()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.integer()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]

otherValidations =
  returnType: validators.string()
  ownerName: validators.string(trim: true)
  hasOwner: validators.boolean()
  bounds: [
    validators.string(minLength: 1)
    validators.geohash
    validators.array(minLength: 2)
  ]
  status: validators.array(subValidation: [ validators.string(forceLowerCase: true),
                                            validators.choice(choices: statuses) ])

makeMinMaxes = (result, validators, name) ->
  result["#{name}Min"] = validators
  result["#{name}Max"] = validators

minMaxes = _.transform(minMaxValidations, makeMinMaxes)
#logger.debug minMaxes, true

transforms = _.extend {}, otherValidations, minMaxes


required =
  bounds: undefined
  status: []
  ownerName: ""

_tableName = sqlHelpers.tableName(PropertyDetails)

_getDefaultQuery = ->
  sqlHelpers.select(db.knex, "filter", true)
  .from(_tableName)

_getFilterSummaryAsQuery = (state, filters, limit = 2000, query = _getDefaultQuery()) ->
  # logger.debug filters, true
    return [] if !filters or !filters?.status?.length
    # save out for use with saved properties

    query.limit(limit) if limit
    sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)

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

    #might not need anymore due to leaflet
    # if _getZoom(state.map_position) >= zoomThresh.ordering or _.contains(filters.status, filterStatusesEnum.not_for_sale)
    #   sqlHelpers.orderByDistanceFromPoint(query, 'geom_point_raw', Point(state.map_position.center))

    # logger.sql query.toString()
    query

module.exports =
  tableName:_tableName

  getDefaultQuery: _getDefaultQuery

  validateAndTransform: (state, rawFilters) ->
    # note this is looking at the pre-transformed status filter
    if !rawFilters.status?.length && (!state?.properties_selected || _.size(state.properties_selected) == 0)
      # we know there is absolutely nothing to select, GTFO before we do any real work
      logger.debug 'GTFO'
      return

    # logger.debug 'rawFilters: \n'
    # logger.debug rawFilters, true
    requestUtil.query.validateAndTransform(rawFilters, transforms, required)

  getFilterSummaryAsQuery: _getFilterSummaryAsQuery

  getFilterSummary: (state, filters, limit, query) ->
    Promise.try () ->
      _getFilterSummaryAsQuery(state, filters, limit, query)
