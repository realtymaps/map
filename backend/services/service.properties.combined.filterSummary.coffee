Promise = require "bluebird"
logger = require('../config/logger').spawn('service:property:filterSummary:combined')
validation = require "../utils/util.validation"
sqlHelpers = require "./../utils/util.sql.helpers"
filterStatuses = require "../enums/filterStatuses"
filterAddress = require "../enums/filterAddress"
filterPropertyType = require "../enums/filterPropertyType"
_ = require "lodash"
tables = require "../config/tables"
cluster = require '../utils/util.sql.manual.cluster.combined'
{currentProfile} = require '../../common/utils/util.profile'

dbFn = tables.property.combined

validators = validation.validators

statuses = filterStatuses.keys

propertyTypes = filterPropertyType.keys

minMaxFilterValidations =
  price: [validators.string(replace: [/[$,]/g, ""]), validators.integer()]
  listedDays: validators.integer()
  beds: validators.integer()
  baths: validators.float()
  acres: validators.float()
  sqft: [ validators.string(replace: [/,/g, ""]), validators.integer() ]
  closeDate: validators.datetime()

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
            propertyType: [
              validators.string()
              validators.choice(choices: propertyTypes)
            ]
            hasImages: validators.boolean(truthy: true, falsy: false)
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
  sqlHelpers.select(dbFn(), "filterCombined", true)

_getResultCount = (validatedQuery) ->
  # obtain a count(*)-style select query
  query = sqlHelpers.selectCountDistinct(dbFn())
  # apply the validatedQuery (mostly "where" clause stuff)
  query = _getFilterSummaryAsQuery(validatedQuery, null, query)
  query

getPermissions = (req) -> Promise.try ->
  # Skip permissions for superusers
  if req.user.is_superuser
    return superuser: true
  else
    permissions =
      fips: []
      mls: []

    # Limit to FIPS codes and verified MLS for this user
    permissions.fips.push(req.user.fips_codes...)
    permissions.mls.push(req.user.mlses_verified...)

    # Include by proxy MLS available to project owner
    profile = currentProfile(req.session)

    if profile.parent_auth_user_id? && profile.parent_auth_user_id != req.user.id
      return tables.auth.user()
        .select('mlses_verified')
        .where('id', profile.parent_auth_user_id).then ([owner]) ->
          permissions.mls_proxy = owner.mlses_verified # NOTE: spelling/capitalization mismatches may exist
          permissions

    return permissions

queryPermissions = (query, permissions) ->
  mls = _.union(permissions.mls, permissions.mls_proxy)
  query.where ->
    if permissions.fips && mls
      @.where ->
        @.where("data_source_type", "county")
        sqlHelpers.whereIn(@, "fips_code", permissions.fips)
      @.orWhere ->
        @.where("data_source_type", "mls")
        sqlHelpers.whereIn(@, "data_source_id", mls)
    else if mls
      @.where("data_source_type", "mls")
      sqlHelpers.whereIn(@, "data_source_id", mls)
    else if permissions.fips
      @.where("data_source_type", "county")
      sqlHelpers.whereIn(@, "fips_code", permissions.fips)
    else if !permissions.superuser
      @.whereRaw("FALSE")

scrubPermissions = (data, permissions) ->
  if (data.data_source_type == 'county' && permissions.fips.indexOf(data.fips_code) == -1) ||
      (data.data_source_type == 'mls' && permissions.mls.indexOf(data.data_source_id) == -1)
    delete data.subscriber_groups
    delete data.owner_name
    delete data.owner_name_2
    delete data.owner_address

_getFilterSummaryAsQuery = (validatedQuery, limit = 2000, query = _getDefaultQuery()) ->
  {bounds, state, permissions} = validatedQuery
  {filters} = state
  return query if !filters?.status?.length
  throw new Error('knex starting query missing!') if !query

  # Add permissions
  queryPermissions(query, permissions)

  # Remainder of query is grouped so we get SELECT .. WHERE (permissions) AND (filters)
  query.where ->
    @.whereNotNull('geometry')

    @.limit(limit) if limit
    if bounds
      sqlHelpers.whereInBounds(@, "#{dbFn.tableName}.geometry_raw", bounds)

    # handle property status filtering
    # 4 possible status options (see parcelEnums.coffee): 'for sale', 'pending', 'sold', 'not for sale'
    if filters.status.length < statuses.length
      # only need to do any filtering if not all available statuses are selected
      @.where () ->
        # in the data, there are actually only 3 possible status options: 'sold' and 'not for sale' are both lumped
        # together as 'not for sale' in the data, and are differentiated here based on whether the close_date is within 1
        # year of now
        sold = false
        offMarket = false
        hardStatuses = []
        for status in filters.status
          if status == 'sold'
            sold = true
          else if status == 'not for sale'
            offMarket = true
          else
            hardStatuses.push(status)

        if sold && offMarket
          # in this case, we don't actually need to differentiate them
          hardStatuses.push('not for sale')
        else if sold
          this.orWhere () ->
            this.where("#{dbFn.tableName}.status", 'not for sale')
            this.whereRaw("#{dbFn.tableName}.close_date >= (now()::DATE - '1 year'::INTERVAL)")
        else if offMarket
          this.orWhere () ->
            this.where("#{dbFn.tableName}.status", 'not for sale')
            this.where () ->
              this.whereRaw("#{dbFn.tableName}.close_date < (now()::DATE - '1 year'::INTERVAL)")
              this.orWhereNull("#{dbFn.tableName}.close_date")

        if hardStatuses.length > 0
          sqlHelpers.orWhereIn(this, "#{dbFn.tableName}.status", hardStatuses)

    sqlHelpers.between(@, "#{dbFn.tableName}.price", filters.priceMin, filters.priceMax)
    sqlHelpers.between(@, "#{dbFn.tableName}.sqft_finished", filters.sqftMin, filters.sqftMax)
    sqlHelpers.between(@, "#{dbFn.tableName}.acres", filters.acresMin, filters.acresMax)

    if filters.bedsMin
      @.where("#{dbFn.tableName}.bedrooms", ">=", filters.bedsMin)

    if filters.bathsMin
      @.where("#{dbFn.tableName}.baths_total", ">=", filters.bathsMin)

    if filters.hasOwner?
      # only checking owner_name here and now owner_name2 because we do normalization in the property summary
      # table that ensures we never have owner_name2 if we don"t have owner_name -- therefore checking
      # only owner_name does the same thing and creates a more efficient query
      if filters.hasOwner
        @.whereNotNull("#{dbFn.tableName}.owner_name")
      else
        @.whereNull("#{dbFn.tableName}.owner_name")

    if filters.ownerName
      # need to avoid any characters that have special meanings in regexes
      # then split on whitespace and commas to get chunks to search for
      patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\s]/), (result, chunk) ->
        if !chunk
          return
        # make dashes and apostraphes optional, can be missing or replaced with a space in the name text
        # since this is after the split, a space here will be an actual part of the search
        result.push chunk.replace(/(["-])/g, "[$1 ]?")
      sqlHelpers.allPatternsInAnyColumn(@, patterns, ["#{dbFn.tableName}.owner_name", "#{dbFn.tableName}.owner_name_2"])

    if filters.listedDaysMin
      @.where("days_on_market", ">=", filters.listedDaysMin)
    if filters.listedDaysMax
      @.where("days_on_market", "<=", filters.listedDaysMax)

    if filters.propertyType
      @.where("#{dbFn.tableName}.property_type", filters.propertyType)

    sqlHelpers.between(@, "#{dbFn.tableName}.close_date", filters.closeDateMin, filters.closeDateMax)

    if filters.hasImages
      @.where("photos", "!=", "{}")

    # If full address available, include matched property in addition to other matches regardless of filters
    filters.address = _.pick filters.address, filterAddress.keys
    filters.address = _.omit filters.address, _.isEmpty
    if _.keys(filters.address).length == filterAddress.keys.length
      logger.debug filters.address
      addressString = "#{filters.address.street_address_num} #{filters.address.street_address_name} #{filters.address.city}, #{filters.address.state} #{filters.address.zip.slice(0,5)}"
      logger.debug "addressString: #{addressString}"
      @.orWhereRaw "? like concat('%',array_to_string(ARRAY(select json_array_elements_text(address->'lines')), ' '),'%')", [addressString]
      @.orWhereRaw "array_to_string(ARRAY(select json_array_elements_text(address->'lines')), ' ') like ?", ["%#{addressString}%"]

  logger.debug -> query.toString()
  query

transformProperties = (properties) ->
  streetRe = /^(\d+)\s*(.+)/
  cityRe = /^(.+),\s*(.+)/
  for prop in properties
    scrubPermissions(prop)

    # This can be removed once mv_property_details is gone. Note: front-end will need updating
    if prop.address?
      # Remove the first line if there are more than 3 -- it will be a "care of so-and-so" line
      lines = prop.address.lines.slice(-3)
      streetLine = lines[0].match(streetRe)
      cityLine = lines[1].match(cityRe)
      prop.street_address_num = streetLine[1]
      prop.street_address_name = streetLine[2]
      prop.city = cityLine[1]
      prop.state = cityLine[2]
      prop.zip = lines[2] ? '99999'

module.exports =
  transforms: transforms
  transformProperties: transformProperties

  getDefaultQuery: _getDefaultQuery

  getFilterSummaryAsQuery: _getFilterSummaryAsQuery
  getResultCount: _getResultCount

  getFilterSummary: (filters, limit, query) ->
    Promise.try () ->
      _getFilterSummaryAsQuery(filters, limit, query)

  cluster: cluster
  getPermissions: getPermissions
  queryPermissions: queryPermissions
  scrubPermissions: scrubPermissions
