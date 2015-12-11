config = require '../../common/config/commonConfig'
base = require './service.properties.base.filterSummary'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
Point = require('../../common/utils/util.geometries').Point
sqlCluster = require '../utils/util.sql.manual.cluster'
Promise = require 'bluebird'
logger = require '../config/logger'
propMerge = require '../utils/util.properties.merge'
{toLeafletMarker} =  require('../utils/crud/extensions/util.crud.extension.user').route
_ = require 'lodash'
validation = require '../utils/util.validation'

_getZoom = (position) ->
  position.center.zoom

_handleReturnType = (filterSummaryImpl, state, queryParams, limit, zoom = 13) ->
  returnAs = queryParams.returnType
  logger.debug "_handleReturnType: " + returnAs
  _default = ->
    query = filterSummaryImpl.getFilterSummaryAsQuery(state, queryParams, 800)

    # include saved id's in query so no need to touch db later
    propertiesIds = _.keys(state.properties_selected)
    if propertiesIds.length > 0
      sqlHelpers.orWhereIn(query, 'rm_property_id', propertiesIds)

    # remove dupes
    # include "savedDetails" for saved props
    # logger.debug query.toString()
    query.then (properties) ->
      propMerge.updateSavedProperties(state, properties)

    # more data arranging
    .then (properties) ->
      properties = toLeafletMarker properties, ['geom_point_json', 'geometry']
      props = indexBy(properties, false)
      props

  _cluster = ->
    filterSummaryImpl.getFilterSummary(state, queryParams, limit, sqlCluster.clusterQuery(zoom))
    .then (properties) ->
      sqlCluster.fillOutDummyClusterIds(properties)
    .then (properties) ->
      properties

  _geojsonPolys = ->
    query = filterSummaryImpl.getFilterSummaryAsQuery(state, queryParams, 2000, query)
    return Promise.resolve([]) unless query

    # include saved id's in query so no need to touch db later
    propertiesIds = _.keys(state.properties_selected)
    if propertiesIds.length > 0
      sqlHelpers.orWhereIn(query, 'rm_property_id', propertiesIds)

    # data formatting
    query.then (data) ->
      geojson =
        'type': 'FeatureCollection'
        'features': propMerge.updateSavedProperties(state, data).map (d) ->
          d.type = 'Feature'
          d.properties = {}
          d

  _clusterOrDefault = ->
    filterSummaryImpl.getResultCount(state, queryParams).then (data) ->
      if data[0].count > config.backendClustering.resultThreshold
        return _cluster()
      else
        return _default()

  handles =
    cluster: _cluster
    geojsonPolys: _geojsonPolys
    default: _default
    clusterOrDefault: _clusterOrDefault

  handle = handles[returnAs] or handles.default
  handle()

_validateAndTransform = (state, rawFilters, localTransforms) ->
  # note this is looking at the pre-transformed status filter
  if !rawFilters.status?.length && (!state?.properties_selected || _.size(state.properties_selected) == 0)
    # we know there is absolutely nothing to select, GTFO before we do any real work
    logger.debug 'GTFO'
    return

  logger.debug 'validating transforms'
  validatedQuery = validation.validateAndTransform(rawFilters, localTransforms)
  logger.debug 'validated transforms'
  validatedQuery

module.exports =
  getFilterSummary: (state, rawFilters, limit = 2000, filterSummaryImpl = base) ->
    # logger.debug.green rawFilters, true
    _zoom = null
    Promise.try ->
      _validateAndTransform(state, rawFilters, filterSummaryImpl.transforms)
    .then (queryParams) ->
      # logger.debug queryParams, true
      _handleReturnType(filterSummaryImpl, state, queryParams, limit, _getZoom(state.map_position))
