Promise = require "bluebird"
logger = require('../config/logger').spawn('service:filterSummary:base')
validation = require "../utils/util.validation"
sqlHelpers = require "./../utils/util.sql.helpers"
filterStatuses = require "../enums/filterStatuses"
filterAddress = require "../enums/filterAddress"
_ = require "lodash"
tables = require "../config/tables"

dbFn = tables.property.propertyDetails

validators = validation.validators

statuses = filterStatuses.keys

minMaxFilterValidations =
  price: [validators.string(replace: [/[$,]/g, ""]), validators.integer()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.integer()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]

transforms = do ->
  makeMinMaxes = (result, validators, name) ->
    result["#{name}Min"] = validators
    result["#{name}Max"] = validators

  minMaxFilterValidations = _.transform(minMaxFilterValidations, makeMinMaxes)
  state: validators.object
    subValidateSeparate:
      filters: [
        validators.object
          subValidateSeparate: _.extend minMaxFilterValidations,
            ownerName: [validators.string(trim: true), validators.defaults(defaultValue: "")]
            hasOwner: validators.boolean()
            status: [
              validators.array
                subValidateEach: [
                  validators.string(forceLowerCase: true)
                  validators.choice(choices: statuses)
                ]
              validators.defaults(defaultValue: [])
            ]
          validators.defaults(defaultValue: {})
      ]
  bounds:
    transform: [
      validators.string(minLength: 1)
      validators.geohash
      validators.array(minLength: 2)
    ]
    required: true
  address: [
    validators.object()
    validators.defaults(defaultValue: {})
  ]
  returnType: validators.string()

_getDefaultQuery = ->
  sqlHelpers.select(dbFn(), "filter", true, "distinct on (rm_property_id)")

_getResultCount = (validatedQuery) ->
  # obtain a count(*)-style select query
  query = sqlHelpers.selectCountDistinct(dbFn())
  # apply the validatedQuery (mostly "where" clause stuff)
  query = _getFilterSummaryAsQuery(validatedQuery, null, query)
  query

_getFilterSummaryAsQuery = (validatedQuery, limit = 2000, query = _getDefaultQuery()) ->
  logger.debug -> validatedQuery

  {bounds, state} = validatedQuery
  {filters} = state
  return query if !filters?.status?.length
  throw new Error('knex starting query missing!') if !query

  query.limit(limit) if limit
  if bounds
    sqlHelpers.whereInBounds(query, "#{dbFn.tableName}.geom_polys_raw", bounds)

  if filters.status.length < statuses.length
    sqlHelpers.whereIn(query, "#{dbFn.tableName}.rm_status", filters.status)

  sqlHelpers.between(query, "#{dbFn.tableName}.price", filters.priceMin, filters.priceMax)
  sqlHelpers.between(query, "#{dbFn.tableName}.finished_sqft", filters.sqftMin, filters.sqftMax)
  sqlHelpers.between(query, "#{dbFn.tableName}.acres", filters.acresMin, filters.acresMax)

  if filters.bedsMin
    query.where("#{dbFn.tableName}.bedrooms", ">=", filters.bedsMin)

  if filters.bathsMin
    query.where("#{dbFn.tableName}.baths_full", ">=", filters.bathsMin)

  if filters.hasOwner?
    # only checking owner_name here and now owner_name2 because we do normalization in the property summary
    # table that ensures we never have owner_name2 if we don"t have owner_name -- therefore checking
    # only owner_name does the same thing and creates a more efficient query
    if filters.hasOwner
      query.whereNotNull("#{dbFn.tableName}.owner_name")
    else
      query.whereNull("#{dbFn.tableName}.owner_name")

  if filters.ownerName
    # need to avoid any characters that have special meanings in regexes
    # then split on whitespace and commas to get chunks to search for
    patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\s]/), (result, chunk) ->
      if !chunk
        return
      # make dashes and apostraphes optional, can be missing or replaced with a space in the name text
      # since this is after the split, a space here will be an actual part of the search
      result.push chunk.replace(/(["-])/g, "[$1 ]?")
    sqlHelpers.allPatternsInAnyColumn(query, patterns, ["#{dbFn.tableName}.owner_name", "#{dbFn.tableName}.owner_name2"])

  if filters.listedDaysMin
    sqlHelpers.ageOrDaysFromStartToNow(query, "listing_age_days", "listing_start_date", ">=", filters.listedDaysMin)
  if filters.listedDaysMax
    sqlHelpers.ageOrDaysFromStartToNow(query, "listing_age_days", "listing_start_date", "<=", filters.listedDaysMax)

  # If full address available, include matched property in addition to other matches regardless of filters
  filters.address = _.pick filters.address, filterAddress.keys
  filters.address = _.omit filters.address, _.isEmpty
  if _.keys(filters.address).length == filterAddress.keys.length
    query.orWhere ->
      for key, value of filters.address
        if key == 'zip'
          # Match 5-digit zip even if DB contains zip ext
          @where("#{dbFn.tableName}.#{key}", "like", "#{value}%")
        else
          @where("#{dbFn.tableName}.#{key}", "=", value)

  query

module.exports =
  transforms: transforms

  getDefaultQuery: _getDefaultQuery

  getFilterSummaryAsQuery: _getFilterSummaryAsQuery
  getResultCount: _getResultCount

  getFilterSummary: (filters, limit, query) ->
    Promise.try () ->
      _getFilterSummaryAsQuery(filters, limit, query)
