Promise = require "bluebird"
logger = require "../config/logger"
validation = require "../utils/util.validation"
sqlHelpers = require "./../utils/util.sql.helpers"
filterStatuses = require "../enums/filterStatuses"
filterAddress = require "../enums/filterAddress"
_ = require "lodash"
tables = require "../config/tables"
tableNames = require "../config/tableNames"

dbFn = tables.property.propertyDetails
dbTableName = tableNames.property.propertyDetails

validators = validation.validators

statuses = filterStatuses.keys

minMaxValidations =
  price: [validators.string(replace: [/[$,]/g, ""]), validators.integer()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.integer()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]

otherValidations =
  returnType: validators.string()
  ownerName: [validators.string(trim: true), validators.defaults(defaultValue: "")]
  hasOwner: validators.boolean()
  bounds:
    transform: [
      validators.string(minLength: 1)
      validators.geohash
      validators.array(minLength: 2)
    ]
    required: true
  status: [
    validators.array
      subValidateEach: [
        validators.string(forceLowerCase: true)
        validators.choice(choices: statuses)
      ]
    validators.defaults(defaultValue: [])
  ]
  address: [
    validators.object
      pluck: filterAddress.keys
      subValidateEach: [
        validators.string(minLength: 1)
      ]
    validators.defaults(defaultValue: [])
  ]


makeMinMaxes = (result, validators, name) ->
  result["#{name}Min"] = validators
  result["#{name}Max"] = validators

minMaxes = _.transform(minMaxValidations, makeMinMaxes)

transforms = _.extend {}, otherValidations, minMaxes

_getDefaultQuery = ->
  sqlHelpers.select(dbFn(), "filter", true, "distinct on (rm_property_id)")

_getResultCount = (state, filters) ->
  # obtain a count(*)-style select query
  query = sqlHelpers.selectCountDistinct(dbFn())
  # apply the state & filters (mostly "where" clause stuff)
  query = _getFilterSummaryAsQuery(state, filters, null, query)
  query

_getFilterSummaryAsQuery = (state, filters, limit = 2000, query = _getDefaultQuery()) ->
  throw new Error('filters undefined') if !filters
  throw new Error('filters.status empty') if !filters?.status?.length
  throw new Error('knex starting query missing!') if !query

  query.limit(limit) if limit
  if filters.bounds
    sqlHelpers.whereInBounds(query, "#{dbTableName}.geom_polys_raw", filters.bounds)

  if filters.status.length < statuses.length
    sqlHelpers.whereIn(query, "#{dbTableName}.rm_status", filters.status)

  sqlHelpers.between(query, "#{dbTableName}.price", filters.priceMin, filters.priceMax)
  sqlHelpers.between(query, "#{dbTableName}.finished_sqft", filters.sqftMin, filters.sqftMax)
  sqlHelpers.between(query, "#{dbTableName}.acres", filters.acresMin, filters.acresMax)

  if filters.bedsMin
    query.where("#{dbTableName}.bedrooms", ">=", filters.bedsMin)

  if filters.bathsMin
    query.where("#{dbTableName}.baths_full", ">=", filters.bathsMin)

  if filters.hasOwner?
    # only checking owner_name here and now owner_name2 because we do normalization in the property summary
    # table that ensures we never have owner_name2 if we don"t have owner_name -- therefore checking
    # only owner_name does the same thing and creates a more efficient query
    if filters.hasOwner
      query.whereNotNull("#{dbTableName}.owner_name")
    else
      query.whereNull("#{dbTableName}.owner_name")

  if filters.ownerName
    # need to avoid any characters that have special meanings in regexes
    # then split on whitespace and commas to get chunks to search for
    patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\s]/), (result, chunk) ->
      if !chunk
        return
      # make dashes and apostraphes optional, can be missing or replaced with a space in the name text
      # since this is after the split, a space here will be an actual part of the search
      result.push chunk.replace(/(["-])/g, "[$1 ]?")
    sqlHelpers.allPatternsInAnyColumn(query, patterns, ["#{dbTableName}.owner_name", "#{dbTableName}.owner_name2"])

  if filters.listedDaysMin
    sqlHelpers.ageOrDaysFromStartToNow(query, "listing_age_days", "listing_start_date", ">=", filters.listedDaysMin)
  if filters.listedDaysMax
    sqlHelpers.ageOrDaysFromStartToNow(query, "listing_age_days", "listing_start_date", "<=", filters.listedDaysMax)

  for key, value of filters.address
    query.orWhere("#{dbTableName}.#{key}", "=", value)

  query

module.exports =
  transforms: transforms

  getDefaultQuery: _getDefaultQuery

  getFilterSummaryAsQuery: _getFilterSummaryAsQuery
  getResultCount: _getResultCount

  getFilterSummary: (state, filters, limit, query) ->
    Promise.try () ->
      _getFilterSummaryAsQuery(state, filters, limit, query)
