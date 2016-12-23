Promise = require "bluebird"
logger = require('../config/logger').spawn('service:filterSummary:combined')
sqlHelpers = require "./../utils/util.sql.helpers"
_ = require "lodash"
tables = require "../config/tables"
internals = require './service.properties.combined.filterSummary.internals'
dbFn = tables.finalized.combined
combinedTransforms = require('../utils/transforms/transforms.properties.coffee').filterSummary
{statuses} = require "../enums/filterStatuses"
{distance} = require '../../common/utils/enums/util.enums.map.coord_system.coffee'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'

getDefaultQuery = ->
  sqlHelpers.select(dbFn(), "filter", true)

_collectFipsMLS = (user, profile) -> Promise.try ->
  permissions =
    fips: []
    mls: []

  # Limit to FIPS codes and verified MLS for this user
  permissions.fips.push(user.fips_codes...)
  permissions.mls.push(user.mlses_verified...)

  # Include by proxy MLS available to project owner
  Promise.try () ->
    if profile?.parent_auth_user_id? && profile?.parent_auth_user_id != user.id
      tables.auth.user()
        .select('mlses_verified')
        .where('id', profile.parent_auth_user_id).then ([owner]) ->
          logger.debug () -> "Found owner: #{JSON.stringify(owner)}"
          permissions.mls_proxy = owner.mlses_verified # NOTE: spelling/capitalization mismatches may exist
  .then () ->
    logger.debug "@@@@ permissions @@@@"
    logger.debug permissions
    return permissions

getFipsMLSForUser = (userid) ->
  tables.auth.user()
  .select(['id', 'fips_codes', 'mlses_verified'])
  .where(id: userid)
  .then ([user]) ->
    _collectFipsMLS(user)


getPermissions = (profile) -> Promise.try ->
  logger.debug () -> "Getting permissions..."
  tables.auth.user()
  .select(['id', 'is_superuser', 'fips_codes', 'mlses_verified'])
  .where(id: profile.auth_user_id)
  .then ([user]) ->
    if !user
      logger.debug "no user found."
      return {}
    logger.debug () -> "Found user: #{JSON.stringify(user)}"

    # Skip permissions for superusers
    if user.is_superuser
      return superuser: true
    else
      _collectFipsMLS(user, profile)


queryPermissions = (query, permissions = {}) ->
  mls = _.union(permissions.mls, permissions.mls_proxy)
  query.where ->
    if permissions.fips?.length && mls?.length
      @where ->
        @where("data_source_type", "county")
        sqlHelpers.whereIn(@, "fips_code", permissions.fips)
      @orWhere ->
        @where("data_source_type", "mls")
        sqlHelpers.whereIn(@, tables.finalized.combined.tableName + ".data_source_id", mls)
    else if mls?.length
      @where("data_source_type", "mls")
      sqlHelpers.whereIn(@, tables.finalized.combined.tableName + ".data_source_id", mls)
    else if permissions.fips?.length
      @where("data_source_type", "county")
      sqlHelpers.whereIn(@, "fips_code", permissions.fips)
    else if !permissions.superuser
      @whereRaw("FALSE")

scrubPermissions = (data, permissions) ->
  logger.debug -> permissions

  if !permissions.superuser
    for row in data
      if (row.data_source_type == 'county' && permissions.fips.indexOf(row.fips_code) == -1) ||
           (row.data_source_type == 'mls' && permissions.mls.indexOf(row.data_source_id) == -1)
        delete row.subscriber_groups
        delete row.owner_name
        delete row.owner_name_2
        delete row.owner_address

queryFilters = ({query, filters, bounds, queryParams}) ->
  logger.debug queryParams
  logger.debug () -> "in queryFilters"
  # Remainder of query is grouped so we get SELECT .. WHERE (permissions) AND (filters)

  if filters?.status?.length

    query.where ->
      if bounds?
        sqlHelpers.whereInBounds(@, "#{dbFn.tableName}.geometry_raw", bounds)

      if radius = queryParams.geometry?.radius
        geometry = type: 'Point', coordinates: queryParams.geometry.coordinates
        @whereRaw(
          "ST_DWithin(geometry_center_raw, ST_SetSRID(ST_GeomFromGeoJSON(?), #{coordSys.UTM}), ?)",
          [geometry, radius / distance.METERS_PER_EARTH_RADIUS]
        )
      else if queryParams.geometry
        @whereRaw("ST_Within(geometry_center_raw, ST_SetSRID(ST_GeomFromGeoJSON(?), #{coordSys.UTM}))", [queryParams.geometry])

      # handle property status filtering
      # 3 possible status options (see parcelEnums.coffee): 'for sale', 'pending', 'sold'
      # only need to do any filtering if not all available statuses are selected or all statuses
      #   are selected and sold date range is provided
      if filters.status.length < statuses.length || filters.soldRange
        @where () ->
          sold = false
          hardStatuses = []
          for status in filters.status
            if status == 'sold'
              sold = true
            else
              hardStatuses.push(status)

          if sold
            @orWhere () ->
              @where("#{dbFn.tableName}.status", 'sold')
              if filters.closeDateMin || filters.closeDateMax
                sqlHelpers.between(@, "#{dbFn.tableName}.close_date", filters.closeDateMin, filters.closeDateMax)
              else if filters.soldRange && filters.soldRange != 'all'
                @whereRaw("#{dbFn.tableName}.close_date >= (now()::DATE - '#{filters.soldRange}'::INTERVAL)")

          if hardStatuses.length > 0
            sqlHelpers.orWhereIn(@, "#{dbFn.tableName}.status", hardStatuses)

      sqlHelpers.between(@, "#{dbFn.tableName}.price", filters.priceMin, filters.priceMax)
      sqlHelpers.between(@, "#{dbFn.tableName}.sqft_finished", filters.sqftMin, filters.sqftMax)
      sqlHelpers.between(@, "#{dbFn.tableName}.acres", filters.acresMin, filters.acresMax)

      if filters.bedsMin
        @where("#{dbFn.tableName}.bedrooms", ">=", filters.bedsMin)

      if filters.bathsMin
        @where("#{dbFn.tableName}.baths_total", ">=", filters.bathsMin)

      if filters.ownerName
        # need to avoid any characters that have special meanings in regexes
        # then split on whitespace and commas to get chunks to search for
        patterns = _.transform filters.ownerName.replace(/[\\|().[\]*+?{}^$]/g, " ").split(/[,\s]/), (result, chunk) ->
          if !chunk
            return
          # make dashes and apostrophes optional, can be missing or replaced with a space in the name text
          # since this is after the split, a space here will be an actual part of the search
          result.push chunk.replace(/(['-])/g, "[$1 ]?")
        sqlHelpers.allPatternsInAnyColumn(@, patterns, ["#{dbFn.tableName}.owner_name", "#{dbFn.tableName}.owner_name_2"])

      if filters.listedDaysMin
        @whereRaw("""
          (CASE
              WHEN data_combined.status = 'for sale' or (data_combined.status = 'pending' and data_combined.days_on_market IS NULL and data_combined.days_on_market_cumulative IS NULL)
              THEN (data_combined.days_on_market_filter + (NOW()::DATE - data_combined.up_to_date::DATE))
              ELSE data_combined.days_on_market_filter
          END) >= ?""", filters.listedDaysMin)
      if filters.listedDaysMax
        @whereRaw("""
          (CASE
              WHEN data_combined.status = 'for sale' or (data_combined.status = 'pending' and data_combined.days_on_market IS NULL and data_combined.days_on_market_cumulative IS NULL)
              THEN (data_combined.days_on_market_filter + (NOW()::DATE - data_combined.up_to_date::DATE))
              ELSE data_combined.days_on_market_filter
          END) <= ?""", filters.listedDaysMax)


      if filters.propertyType
        @where("#{dbFn.tableName}.property_type", filters.propertyType)

      if filters.hasImages
        @whereNotNull("photos")
        @where("photos", "!=", "{}")

      if filters.yearBuilt
        @whereRaw("year_built->>'value' = ?", [filters.yearBuilt])

      if queryParams.pins?.length
        sqlHelpers.orWhereIn(@, 'rm_property_id', queryParams.pins)

      if queryParams.favorites?.length
        sqlHelpers.orWhereIn(@, 'rm_property_id', queryParams.favorites)

  else if queryParams.pins || queryParams.favorites
    logger.debug () -> "no status, so query for pins and favorites only"
    savedIds = (queryParams.pins || []).concat(queryParams.favorites || [])

    sqlHelpers.whereIn(query, 'rm_property_id', savedIds)
  else
    logger.debug () -> "no status and no pins or favorites, so no query needed"
    mockQuery = Promise.resolve([])
    mockQuery.toString = () ->
      'NOTHING TO QUERY!'
    return mockQuery

  query



getFilterSummaryAsQuery = ({queryParams, limit, query, permissions}) ->
  query ?= getDefaultQuery()
  query.leftOuterJoin(tables.finalized.photo.tableName, "#{tables.finalized.combined.tableName}.data_source_uuid", "#{tables.finalized.photo.tableName}.data_source_uuid")

  {bounds, state} = queryParams
  {filters} = state || {}

  queryPermissions(query, permissions)
  query.limit(limit) if limit
  queryFilters({query, filters, bounds, queryParams})


module.exports = {
  transforms: combinedTransforms
  getDefaultQuery
  getFilterSummaryAsQuery
  cluster: internals
  getFipsMLSForUser
  getPermissions
  queryPermissions
  scrubPermissions
}
