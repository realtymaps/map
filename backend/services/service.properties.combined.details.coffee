logger = require('../config/logger').spawn('service:property:details:combined')
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
{getPermissions, queryPermissions, scrubPermissions} = require './service.properties.combined.filterSummary'
_ = require 'lodash'

_detailQuery = (queryParams, req) ->
  getPermissions(req)
  .then (permissions) ->
    logger.debug permissions

    # This can be removed once mv_property_details is gone
    columnMap =
      'filter': 'filterCombined'
      'address': 'filterCombined'
      'detail': 'detail_with_disclaimer'
      'all': 'new_all'

    query = sqlHelpers.select(tables.property.combined(), columnMap[queryParams.columns])
    .leftOuterJoin "#{tables.config.mls.tableName}", ->
      @.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")

    queryPermissions(query, permissions)

    # Remainder of query is grouped so we get SELECT .. WHERE (permissions) AND (filters)
    query.where ->
      @.where(active: true)

      if queryParams.rm_property_id?
        sqlHelpers.whereIn(@, 'rm_property_id', queryParams.rm_property_id)
      else if queryParams.geom_point_json?
        sqlHelpers.whereIntersects(@, queryParams.geom_point_json, 'geometry_raw')
        @.limit(1)

    logger.debug query.toString()

    query.then (data = []) ->
      result = {}
      for row in data
        result[row.rm_property_id] ?= { county: null, mls: null }
        result[row.rm_property_id][row.data_source_type] ?= []
        result[row.rm_property_id][row.data_source_type].push(row)

        # Prune subscriber groups and owner info where appropriate
        scrubPermissions(row, permissions)

      result

# Retrieve a single property by rm_property_id OR geom_point_json
getDetail = (req) ->
  validation.validateAndTransform req.validBody,
    rm_prop_id_or_geom_json:
      input: ["rm_property_id", "geom_point_json"]
      transform: validators.pickFirst()
      required: true

    rm_property_id:
      transform: validators.string(minLength: 1)

    geom_point_json:
      transform: [validators.object(), validators.geojson(toCrs: true)]

    columns:
      transform: validators.choice(choices: ['filter', 'address', 'detail', 'all'])
      required: true

  .then (queryParams) ->
    _detailQuery(queryParams, req)

  .then (result) ->
    _.map(result)[0]

# Retrieve a set of properties by rm_property_id (filter data only)
getDetails = (req) ->
  validation.validateAndTransform req.validBody,
    columns:
      transform: validators.choice(choices: ['filter'])
      required: true

    rm_property_id:
      transform: validators.array()
      required: true

  .then (queryParams) ->
    _detailQuery(queryParams, req)

module.exports = {
  getDetail
  getDetails
}
