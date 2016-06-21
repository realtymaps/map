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
mlsConfigSvc = require './service.mls_config'
geohash = require 'geohash64'

_isOnlyPinned = (queryParams) ->
  !queryParams?.state?.filters?.status?.length

_isNothingPinned = (state) ->
  !state?.pins || _.size(state.pins) == 0

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
          propertiesIds = _.keys(state.pins)
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

            resultsByPropertyId = {}
            propertyIdsByCenterPoint = {}
            resultGroups = {}
            Promise.each properties, (property) ->
              existing = resultsByPropertyId[property.rm_property_id]
              # MLS always replaces Tax data. The most up-to-date MLS record takes precedence.
              if !property.data_source_type? || # Backward-compatibility
                 !existing || (property.data_source_type == 'mls' && existing.data_source_type != 'mls') ||
                  (property.data_source_type == 'mls' && existing.data_source_type != 'mls' &&
                    moment(existing.up_to_date).isBefore(property.up_to_date))

                encodedCenter = geohash.encode([property.geometry_center])
                propertyIdsByCenterPoint[encodedCenter] ?= []
                propertyIdsByCenterPoint[encodedCenter].push(property.rm_property_id)

                resultsByPropertyId[property.rm_property_id] = toLeafletMarker property

                # Ensure saved details are part of the saved props
                if state.pins?[property.rm_property_id]?
                  property.savedDetails = state.pins[property.rm_property_id]

                if property.data_source_type == 'mls'
                  mlsConfigSvc.getByIdCached(property.data_source_id)
                  .then (mlsConfig) ->
                    property.mls_formal_name = mlsConfig?.formal_name
            .then () ->
              Promise.each propertyIdsByCenterPoint, (rm_property_ids, encodedCenter) ->
                if rm_property_ids.length > 0
                  for rm_property_id in rm_property_ids
                    resultGroups[encodedCenter] ?= {}
                    resultGroups[encodedCenter][rm_property_id] = resultsByPropertyId[rm_property_id]
                    delete resultsByPropertyId[rm_property_id]
                else
                  delete propertyIdsByCenterPoint[encodedCenter]
            .then () ->
              {singletons: resultsByPropertyId, groups: resultGroups}

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
