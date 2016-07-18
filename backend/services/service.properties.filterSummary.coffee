config = require '../../common/config/commonConfig'
combined = require './service.properties.combined.filterSummary'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('map:filterSummary')
{toLeafletMarker} =  require('../utils/crud/extensions/util.crud.extension.user').route
_ = require 'lodash'
validation = require '../utils/util.validation'
mlsConfigSvc = require './service.mls_config'
geohash = require 'geohash64'
moment = require 'moment'

module.exports =
  getFilterSummary: ({validBody, profile, limit, filterSummaryImpl}) ->
    limit ?= config.backendClustering.resultThreshold
    filterSummaryImpl ?= combined

    validation.validateAndTransform(validBody, filterSummaryImpl.transforms)
    .then (queryParams) ->

      # Calculate permissions for the current user
      combined.getPermissions(profile)

      .then (permissions) ->
        logger.debug permissions

        # We know there is absolutely nothing to select, GTFO before we do any real work
        if !queryParams
          return []

        # Include saved id's in query so no need to touch db later
        propertyIds = _.keys(profile.pins)
        if propertyIds.length > 0
          queryParams.pins = propertyIds

        cluster = () ->
          clusterQuery = filterSummaryImpl.cluster.clusterQuery(profile.map_position.center.zoom)
          filterSummaryImpl.getFilterSummaryAsQuery({queryParams, limit, query: clusterQuery, permissions})
          .then (properties) ->
            combined.scrubPermissions(properties, permissions)
            filterSummaryImpl.cluster.fillOutDummyClusterIds(properties)

        summary = () ->
          query = filterSummaryImpl.getFilterSummaryAsQuery({queryParams, limit, permissions})
          logger.debug -> query.toString()
          query.then (properties) ->
            combined.scrubPermissions(properties, permissions)

            resultsByPropertyId = {}
            propertyIdsByCenterPoint = {}
            resultGroups = {}
            Promise.each properties, (property) ->
              existing = resultsByPropertyId[property.rm_property_id]
              # MLS always replaces Tax data. The most up-to-date MLS record takes precedence.
              if !existing || (property.data_source_type == 'mls' && existing.data_source_type != 'mls') ||
                  (property.data_source_type == 'mls' && existing.data_source_type != 'mls' &&
                    moment(existing.up_to_date).isBefore(property.up_to_date))

                if filterSummaryImpl == combined
                  encodedCenter = geohash.encode([property.geometry_center?.coordinates])

                  if encodedCenter
                    # This is a map because we only want each property once
                    propertyIdsByCenterPoint[encodedCenter] ?= {}
                    propertyIdsByCenterPoint[encodedCenter][property.rm_property_id] = 1

                resultsByPropertyId[property.rm_property_id] = toLeafletMarker property

                # Ensure saved details are part of the saved props
                for type in ['pins', 'favorites']
                  if profile[type]?[property.rm_property_id]?
                    property.savedDetails = _.extend property.savedDetails || {},
                      profile[type][property.rm_property_id]

                if property.data_source_type == 'mls'
                  mlsConfigSvc.getByIdCached(property.data_source_id)
                  .then (mlsConfig) ->
                    property.mls_formal_name = mlsConfig?.formal_name
            .then () ->
              if filterSummaryImpl == combined
                for encodedCenter, rm_property_ids of propertyIdsByCenterPoint
                  if _.size(rm_property_ids) > 1
                    for rm_property_id of rm_property_ids
                      resultGroups[encodedCenter] ?= {}
                      resultGroups[encodedCenter][rm_property_id] = resultsByPropertyId[rm_property_id]
                      delete resultsByPropertyId[rm_property_id]

                return {singletons: resultsByPropertyId, groups: resultGroups}
              else
                resultsByPropertyId

        switch queryParams.returnType
          when 'clusterOrDefault'
            # Count the number of properties and do clustering if there are enough
            query = filterSummaryImpl.getResultCount({queryParams, permissions})
            logger.debug -> query.toString()
            query.then ([result]) ->
              if result.count > config.backendClustering.resultThreshold
                logger.debug -> "Cluster query for #{result.count} properties - above threshold #{config.backendClustering.resultThreshold}"
                return cluster()
              else
                logger.debug -> "Default query for #{result.count} properties - under threshold #{config.backendClustering.resultThreshold}"
                if result.count == 0
                  return {}
                else
                  return summary()

          when 'cluster'
            cluster()

          else
            summary()
