base = require './service.properties.base.filterSummary'
{geojson_query, getClauseString} = require '../utils/util.sql.helpers'
indexBy = require '../../common/utils/util.indexByWLength'
Point = require('../../common/utils/util.geometries').Point
{clusterQuery, fillOutDummyClusterIds} = require '../utils/util.sql.manual.cluster'
Promise = require "bluebird"
logger = require '../config/logger'
{maybeMergeSavedProperties} = require '../utils/util.properties.merge'
db = require('../config/dbs').properties

_getZoom = (position) ->
  # console.log position, true
  position.center.zoom

_handleReturnType = (state, queryParams, limit, zoom = 13) ->
  returnAs = queryParams.returnType
  # logger.debug "returnAs: #{returnAs}"

  _default = ->
    base.getFilterSummary(state, queryParams, limit)
    .then (properties) ->
      _.uniq properties, (row) ->
         row.rm_property_id
    .then (properties) ->
      maybeMergeSavedProperties(queryParams, properties)
    .then (properties) ->
      _.each properties, (prop) ->
          prop.type = prop.geom_point_json.type
          prop.coordinates = prop.geom_point_json.coordinates
      props = indexBy(properties, false)
      # logger.sql props, true
      props

  handles =
    cluster: ->
      # logger.debug 'clustering'
      base.getFilterSummary(state, queryParams, limit, clusterQuery(zoom))
      .then (properties) ->
        fillOutDummyClusterIds(properties)
      .then (properties) ->
        # logger.debug properties, true
        properties

    geojsonPolys: ->
      # logger.sql 'in geojsonPolys'
      _whereClause =
        getClauseString(base.getFilterSummaryAsQuery(state, queryParams))
        .replace(/'/g,"''")
      query = geojson_query(db, base.tableName, 'geom_polys_json', _whereClause)
      # logger.sql query.toString()
      query

    default: _default

  handle = handles[returnAs] or handles.default
  handle()

module.exports =
  getFilterSummary: (state, rawFilters, limit = 2000) ->
    _zoom = null
    Promise.try ->
      base.validateAndTransform(state, rawFilters)
    .then (queryParams) ->
      # logger.debug queryParams, true
      _handleReturnType(state, queryParams, limit, _getZoom(state.map_position))
