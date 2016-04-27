Promise = require "bluebird"
logger = require('../config/logger').spawn('service:filterSummary:combined')
validation = require "../utils/util.validation"
sqlHelpers = require "./../utils/util.sql.helpers"
filterStatuses = require "../enums/filterStatuses"
filterAddress = require "../enums/filterAddress"
_ = require "lodash"
tables = require "../config/tables"

dbFn = tables.property.combined

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
            address: [
              validators.object()
              validators.defaults(defaultValue: {})
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
  returnType: validators.string()

_getDefaultQuery = ->
  # TODO: Will probably not work due to mls, county, tax rows
  sqlHelpers.select(dbFn(), "filterCombined", true, "distinct on (rm_property_id)")

_getResultCount = (validatedQuery) ->
  # obtain a count(*)-style select query
  query = sqlHelpers.selectCountDistinct(dbFn())
  # apply the validatedQuery (mostly "where" clause stuff)
  query = _getFilterSummaryAsQuery(validatedQuery, null, query)
  query

_getFilterSummaryAsQuery = (validatedQuery, limit = 2000, query = _getDefaultQuery()) ->
  logger.debug -> query.toString()

  # TODO: permissions

  {bounds, state} = validatedQuery
  {filters} = state
  return query if !filters?.status?.length
  throw new Error('knex starting query missing!') if !query

  query.whereNotNull('geometry')

  query.limit(limit) if limit
  if bounds
    query.orWhere ->
      sqlHelpers.whereInBounds(query, "#{dbFn.tableName}.geometry_raw", bounds)

  if filters.status.length < statuses.length
    sqlHelpers.whereIn(query, "#{dbFn.tableName}.status", filters.status)

  sqlHelpers.between(query, "#{dbFn.tableName}.price", filters.priceMin, filters.priceMax)
  sqlHelpers.between(query, "#{dbFn.tableName}.sqft_finished", filters.sqftMin, filters.sqftMax)
  sqlHelpers.between(query, "#{dbFn.tableName}.acres", filters.acresMin, filters.acresMax)

  if filters.bedsMin
    query.where("#{dbFn.tableName}.bedrooms", ">=", filters.bedsMin)

  if filters.bathsMin
    query.where("#{dbFn.tableName}.baths_total", ">=", filters.bathsMin)

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
    sqlHelpers.allPatternsInAnyColumn(query, patterns, ["#{dbFn.tableName}.owner_name", "#{dbFn.tableName}.owner_name_2"])

  if filters.listedDaysMin
    query.where("days_on_market", ">=", filters.listedDaysMin)
  if filters.listedDaysMax
    query.where("days_on_market", "<=", filters.listedDaysMax)

  # TODO: make this work with new json address field (example: {"lines":["3325 West Washington Boulevard","Unit 2","Chicago, IL"],"strength":51})
  # If full address available, include matched property in addition to other matches regardless of filters
  filters.address = _.pick filters.address, filterAddress.keys
  filters.address = _.omit filters.address, _.isEmpty
  if _.keys(filters.address).length == filterAddress.keys.length
    logger.debug filters.address
    addressString = "#{filters.address.street_address_num} #{filters.address.street_address_name} #{filters.address.city} #{filters.address.state} #{filters.address.zip.slice(0,5)}"
    logger.debug "addressString: #{addressString}"
    query.orWhereRaw "? like concat('%',array_to_string(ARRAY(select json_array_elements_text(address->'lines')), ' '),'%')", [addressString]
    query.orWhereRaw "array_to_string(ARRAY(select json_array_elements_text(address->'lines')), ' ') like ?", ["%#{addressString}%"]

  logger.debug query.toString()

  query

module.exports =
  transforms: transforms

  getDefaultQuery: _getDefaultQuery

  getFilterSummaryAsQuery: _getFilterSummaryAsQuery
  getResultCount: _getResultCount

  getFilterSummary: (filters, limit, query) ->
    Promise.try () ->
      _getFilterSummaryAsQuery(filters, limit, query)
