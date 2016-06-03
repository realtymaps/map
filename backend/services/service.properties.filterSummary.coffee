config = require '../../common/config/commonConfig'
base = require './service.properties.base.filterSummary'
combined = require './service.properties.combined.filterSummary'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:filterSummary')
propMerge = require '../utils/util.properties.merge'
{toLeafletMarker} =  require('../utils/crud/extensions/util.crud.extension.user').route
_ = require 'lodash'
validation = require '../utils/util.validation'

_isOnlyPinned = (queryParams) ->
  !queryParams?.state?.filters?.status?.length

_isNothingPinned = (state) ->
  !state?.properties_selected || _.size(state.properties_selected) == 0

module.exports =
  getFilterSummary: ({state, req, limit, filterSummaryImpl}) ->
    limit ?= 2000

    # This block can be removed once mv_property_details is gone
    if !filterSummaryImpl
      if req.validBody.state?.filters?.combinedData == true
        filterSummaryImpl = combined
      else
        filterSummaryImpl = base

    Promise.try ->
      # Note: this is looking at the pre-transformed status filter
      if !(_isOnlyPinned(req.validBody) && _isNothingPinned(state))
        validation.validateAndTransform(req.validBody, filterSummaryImpl.transforms)

    .then (queryParams) ->
      # We know there is absolutely nothing to select, GTFO before we do any real work
      if ! queryParams
        return []

      # Limit to FIPS codes and verified MLS for this user
      # TODO: Proxied MLS data (county data does not need to be proxied since it is only available for Pinned properties)
      if !req.user.is_superuser
        queryParams.state.filters.fips_codes = req.user.fips_codes
        queryParams.state.filters.mlses_verified = req.user.mlses_verified

      _limitByPinnedProps = (query, state, queryParams) ->
        # include saved id's in query so no need to touch db later
        propertiesIds = _.keys(state.properties_selected)
        if propertiesIds.length > 0
          whereClause = if _isOnlyPinned(queryParams) then "whereIn" else "orWhereIn"
          sqlHelpers[whereClause](query, 'rm_property_id', propertiesIds)

      cluster = () ->
        clusterQuery = filterSummaryImpl.cluster.clusterQuery(state.map_position.center.zoom)
        filterSummaryImpl.getFilterSummary(queryParams, limit, clusterQuery)
        .then (properties) ->
          filterSummaryImpl.cluster.fillOutDummyClusterIds(properties)

      summary = () ->
        query = filterSummaryImpl.getFilterSummaryAsQuery(queryParams, 800)
        _limitByPinnedProps(query, state, queryParams)

        # Remove dupes and include "savedDetails" for saved props
        query.then (properties) ->
          propMerge.updateSavedProperties(state, properties)

        .then (properties) ->
          filterSummaryImpl.transformProperties?(properties)
          properties = toLeafletMarker properties
          props = indexBy(properties, false)

      switch queryParams.returnType
        when 'clusterOrDefault'
          # Count the number of properties and do clustering if
          query = filterSummaryImpl.getResultCount(queryParams)
          _limitByPinnedProps(query, state, queryParams)

          query.then ([result]) ->
            if result.count > config.backendClustering.resultThreshold
              logger.debug -> "Cluster query for #{result.count} properties - above threshold #{config.backendClustering.resultThreshold}"
              return cluster()
            else
              logger.debug -> "Default query for #{result.count} properties - under threshold #{config.backendClustering.resultThreshold}"
              return summary()

        when 'cluster'
          cluster()

        else
          summary()
