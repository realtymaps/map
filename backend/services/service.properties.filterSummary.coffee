config = require '../../common/config/commonConfig'
base = require './service.properties.base.filterSummary'
combined = require './service.properties.combined.filterSummary'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
sqlCluster = require '../utils/util.sql.manual.cluster'
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

_limitByPinnedProps = (query, state, queryParams) ->
  # include saved id's in query so no need to touch db later
  propertiesIds = _.keys(state.properties_selected)
  if propertiesIds.length > 0
    whereClause = if _isOnlyPinned(queryParams) then "whereIn" else "orWhereIn"
    logger.debug "whereClause: #{whereClause}"
    sqlHelpers[whereClause](query, 'rm_property_id', propertiesIds)
    # logger.debug.cyan query.toString()

  query

_handleReturnType = ({filterSummaryImpl, state, queryParams, limit}) ->
  returnAs = queryParams.returnType
  logger.debug "_handleReturnType: " + returnAs

  defaultFn = () ->
    query = filterSummaryImpl.getFilterSummaryAsQuery(queryParams, 800)
    query = _limitByPinnedProps(query, state, queryParams)
    # remove dupes
    # include "savedDetails" for saved props
    query.then (properties) ->
      propMerge.updateSavedProperties(state, properties)

    # more data arranging
    .then (properties) ->
      properties = toLeafletMarker properties, ['geom_point_json', 'geometry']
      props = indexBy(properties, false)
      props

  cluster = ->
    filterSummaryImpl.getFilterSummary(queryParams, limit, sqlCluster.clusterQuery(state.map_position.center.zoom))
    .then (properties) ->
      sqlCluster.fillOutDummyClusterIds(properties)
    .then (properties) ->
      properties

  geojsonPolys = () ->
    query = filterSummaryImpl.getFilterSummaryAsQuery(queryParams, 2000, query)
    return Promise.resolve([]) unless query

    # include saved id's in query so no need to touch db later
    propertiesIds = _.keys(state.properties_selected)
    if propertiesIds.length > 0
      sqlHelpers.orWhereIn(query, 'rm_property_id', propertiesIds)

    # data formatting
    query.then (data) ->
      'type': 'FeatureCollection'
      'features': propMerge.updateSavedProperties(state, data).map (d) ->
        d.type = 'Feature'
        d.properties = {}
        d

  clusterOrDefault = () ->
    _limitByPinnedProps(filterSummaryImpl.getResultCount(queryParams), state, queryParams)
    .then (data) ->
      if data[0].count > config.backendClustering.resultThreshold
        return cluster()
      else
        return defaultFn()

  handles = {
    cluster
    geojsonPolys
    default: defaultFn
    clusterOrDefault
  }

  handle = handles[returnAs] or handles.default
  handle()

_validateAndTransform = ({rawFilters, localTransforms}) ->
  # note this is looking at the pre-transformed status filter
  # logger.debug.cyan rawFilters?.state?.filters?.status
  # logger.debug.green state?.properties_selected
  if _isOnlyPinned(rawFilters) && _isNothingPinned(state)
    # we know there is absolutely nothing to select, GTFO before we do any real work
    logger.debug 'GTFO'
    return Promise.resolve()

  logger.debug 'validating transforms'
  validatedQuery = validation.validateAndTransform(rawFilters, localTransforms)
  logger.debug 'validated transforms'
  validatedQuery

module.exports =
  getFilterSummary: (state, rawFilters, limit = 2000, filterSummaryImpl = combined) ->
    Promise.try ->
      _validateAndTransform({rawFilters, localTransforms: filterSummaryImpl.transforms})
    .then (queryParams) ->
      return [] unless queryParams
      _handleReturnType({filterSummaryImpl, state, queryParams, limit})
