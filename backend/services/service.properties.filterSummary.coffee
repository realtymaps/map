base = require './service.properties.base.filterSummary'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
Point = require('../../common/utils/util.geometries').Point
{clusterQuery, fillOutDummyClusterIds} = require '../utils/util.sql.manual.cluster'
Promise = require "bluebird"
logger = require '../config/logger'
propMerge = require '../utils/util.properties.merge'
db = require('../config/dbs').properties
PropertyDetails = require "../models/model.propertyDetails"
_ = require 'lodash'

_getZoom = (position) ->
  # console.log position, true
  position.center.zoom

_handleReturnType = (state, queryParams, limit, zoom = 13) ->
  returnAs = queryParams.returnType
  # logger.debug "returnAs: #{returnAs}"

  _default = ->
    query = base.getFilterSummaryAsQuery(state, queryParams, limit)
    # include saved id's in query so no need to touch db later
    if Object.keys(state.properties_selected).length > 0
      sqlHelpers.orWhereIn(query, 'rm_property_id', _.keys(state.properties_selected))
    query
    # remove dupes
    .then (properties) ->
      _.uniq properties, (row) ->
         row.rm_property_id
    # include "savedDetails" for saved props
    .then (properties) ->
      propMerge.updateSavedProperties(state, properties)
    # more data arranging
    .then (properties) ->
      _.each properties, (prop) ->
        prop.type = prop.geom_point_json.type
        prop.coordinates = prop.geom_point_json.coordinates
      props = indexBy(properties, false)
      props

  handles =
    cluster: ->
      base.getFilterSummary(state, queryParams, limit, clusterQuery(zoom))
      .then (properties) ->
        fillOutDummyClusterIds(properties)
      .then (properties) ->
        properties


    geojsonPolys: ->
      query = sqlHelpers.select(db.knex, 'all_detail_geojson', false).from(sqlHelpers.tableName(PropertyDetails))
      query = base.getFilterSummaryAsQuery(state, queryParams, 2000, query)
      # include saved id's in query so no need to touch db later
      if Object.keys(state.properties_selected).length > 0
        sqlHelpers.orWhereIn(query, 'rm_property_id', _.keys(state.properties_selected))
      # data formatting
      query.then (data) ->
        geojson = 
          "type": "FeatureCollection"
          "features": _.uniq propMerge.updateSavedProperties(state, data), (row) ->
            row.rm_property_id


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
