config = require '../../common/config/commonConfig'
base = require './service.properties.base.filterSummary'
combined = require './service.properties.combined.filterSummary'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:property:filterSummary')
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

      Promise.try ->
        # Calculate permissions for the current user
        filterSummaryImpl.getPermissions?(req)
        .then (permissions) ->
          logger.debug permissions
          permissions

      .then (permissions) ->
        # We know there is absolutely nothing to select, GTFO before we do any real work
        if !queryParams
          return []

        _limitByPinnedProps = (query, state, queryParams) ->
          # include saved id's in query so no need to touch db later
          propertiesIds = _.keys(state.properties_selected)
          if propertiesIds.length > 0
            whereClause = if _isOnlyPinned(queryParams) then "whereIn" else "orWhereIn"
            sqlHelpers[whereClause](query, 'rm_property_id', propertiesIds)

        cluster = () ->
          clusterQuery = filterSummaryImpl.cluster.clusterQuery(state.map_position.center.zoom)
          filterSummaryImpl.getFilterSummaryAsQuery({queryParams, limit, query: clusterQuery, permissions})
          .then (properties) ->
            filterSummaryImpl.scrubPermissions?(properties, permissions)
            filterSummaryImpl.cluster.fillOutDummyClusterIds(properties)

        summary = () ->
          query = filterSummaryImpl.getFilterSummaryAsQuery({queryParams, limit: 800, permissions})
          _limitByPinnedProps(query, state, queryParams)

          query.then (properties) ->
            filterSummaryImpl.scrubPermissions?(properties, permissions)

            result = {}
            for property in properties
              existing = result[property.rm_property_id]
              if property.data_source_type == 'mls' &&
                  (existing?.data_source_type != 'mls' || moment(existing.up_to_date).isBefore(property.up_to_date))
                result[rm_property_id] = toLeafletMarker property, 'geometry_center' # promote coordinate fields

                # Ensure saved details are part of the saved props
                if state.properties_selected?[property.rm_property_id]?
                  property.savedDetails = state.properties_selected[property.rm_property_id]

            result

        switch queryParams.returnType
          when 'clusterOrDefault'
            # Count the number of properties and do clustering if there are enough
            query = filterSummaryImpl.getResultCount({queryParams, permissions})
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
