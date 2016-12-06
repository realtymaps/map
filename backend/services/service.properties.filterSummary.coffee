config = require '../../common/config/commonConfig'
combined = require './service.properties.combined.filterSummary'
logger = require('../config/logger').spawn('service:filterSummary')
{toLeafletMarker} =  require('../utils/crud/extensions/util.crud.extension.user').route
_ = require 'lodash'
validation = require '../utils/util.validation'
mlsConfigSvc = require './service.mls_config'
geohash = require 'geohash64'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
propertiesUtil = require  '../utils/util.properties'

module.exports =
  getFilterSummary: ({validBody, profile, limit, filterSummaryImpl, ignoreSaved}) ->
    limit ?= config.backendClustering.resultThreshold
    filterSummaryImpl ?= combined

    validation.validateAndTransform(validBody, filterSummaryImpl.transforms)
    .then (queryParams) ->
      logger.debug queryParams

      # Calculate permissions for the current user
      combined.getPermissions(profile)

      .then (permissions) ->
        logger.debug permissions

        # We know there is absolutely nothing to select, GTFO before we do any real work
        if !queryParams
          return []

        if !ignoreSaved
          # Include saved id's in query so no need to touch db later
          queryParams.pins = _.keys(profile?.pins || {}) # `|| {}` defensive just in case no `.pins`

          # This helps ensure favorites are accounted for in query for the following edge case requirement:
          #   When no status layers are selected, show only pins and favorites
          queryParams.favorites = _.keys(profile?.favorites || {}) # `|| {}` defensive just in case no `.favorites`


        cluster = () ->
          if !filterSummaryImpl.cluster
            logger.debug -> filterSummaryImpl
            throw new errorHandlingUtils.PartiallyHandledError "filterSummaryImpl.cluster is undefined"

          clusterQuery = filterSummaryImpl.cluster.clusterQuery(profile.map_position.center.zoom)

          # does not need limit as clusterQuery will only return 1 row
          query = filterSummaryImpl.getFilterSummaryAsQuery({queryParams, query: clusterQuery, permissions})

          logger.debug () -> query.toString()

          query.then (properties) ->
            combined.scrubPermissions(properties, permissions)
            filterSummaryImpl.cluster.fillOutDummyClusterIds(properties)

        summary = (limit) ->
          query = filterSummaryImpl.getFilterSummaryAsQuery({queryParams, limit, permissions})
          logger.debug -> query.toString()
          query.then (properties) ->
            if properties.length > config.backendClustering.resultThreshold
              logger.debug -> "Cluster query for #{properties.length} properties - above threshold #{config.backendClustering.resultThreshold}"
              return cluster()

            combined.scrubPermissions(properties, permissions)

            propertyIdsByCenterPoint = {}
            resultGroups = {}
            saves = pins: {}, favorites: {}
            propertiesUtil.eachTrump {collection: properties, trump: 'mls'}, ({result, row}) ->
              property = row
              if queryParams.returnType
                encodedCenter = geohash.encode([property.geometry_center?.coordinates])

                if encodedCenter
                  # This is a map because we only want each property once
                  propertyIdsByCenterPoint[encodedCenter] ?= {}
                  propertyIdsByCenterPoint[encodedCenter][property.rm_property_id] = 1

              result[property.rm_property_id] = toLeafletMarker property

              for type in ['pins', 'favorites']
                if profile[type]?[property.rm_property_id]?
                  # Ensure saved details are part of the saved props
                  property.savedDetails = _.extend property.savedDetails || {},
                    profile[type][property.rm_property_id]
                  # Always return pins/favorites so the font-end can show those added by other uses
                  saves[type][property.rm_property_id] = property

              if property.data_source_type == 'mls' and property.data_source_id?
                mlsConfigSvc.getByIdCached(property.data_source_id)
                .then (mlsConfig) ->
                  property.mls_formal_name = mlsConfig?.formal_name
            .then (resultsByPropertyId) ->
              resultGroupsCtr = 0
              result = if queryParams.returnType
                for encodedCenter, rm_property_ids of propertyIdsByCenterPoint
                  if _.size(rm_property_ids) > 1
                    for rm_property_id of rm_property_ids
                      resultGroups[encodedCenter] ?= {}
                      resultGroups[encodedCenter][rm_property_id] = resultsByPropertyId[rm_property_id]
                      delete resultsByPropertyId[rm_property_id]
                      resultGroupsCtr++

                singletons: resultsByPropertyId
                groups: resultGroups
                saves: saves
                length: properties.length + resultGroupsCtr
              else
                resultsByPropertyId.length = properties.length
                resultsByPropertyId

              logger.debug "Normal Query with length of #{result.length}"
              delete result.length

              result

        logger.debug () -> "queryParams.returnType: #{queryParams.returnType}"

        switch queryParams.returnType
          when 'cluster'
            cluster()
          else
            summary(config.backendClustering.resultThreshold + 1)
