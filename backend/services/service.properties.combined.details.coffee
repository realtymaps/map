logger = require('../config/logger').spawn('service:property:details:combined')
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
{getPermissions, queryPermissions, scrubPermissions} = require './service.properties.combined.filterSummary'
_ = require 'lodash'
mlsConfigSvc = require './service.mls_config'
Promise = require 'bluebird'
moment = require 'moment'

_detailQuery = (queryParams, req) ->
  getPermissions(req)
  .then (permissions) ->
    logger.debug permissions

    # This can be removed once mv_property_details is gone
    columnMap =
      'filter': 'filterCombined'
      'address': 'filterCombined'
      'detail': 'new_all_explicit'
      'all': 'new_all_explicit'

    query = sqlHelpers.select(tables.finalized.combined(), columnMap[queryParams.columns])
    .leftOuterJoin "#{tables.config.mls.tableName}", ->
      @.on("#{tables.config.mls.tableName}.id", "#{tables.finalized.combined.tableName}.data_source_id")

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

      # Prune subscriber groups and owner info where appropriate
      scrubPermissions(data, permissions)

      Promise.map data, (row) ->
        result[row.rm_property_id] ?= { county: null, mls: null }
        propertyList = result[row.rm_property_id][row.data_source_type] ?= []

        if moment(row.up_to_date).isAfter(propertyList[0]?.up_to_date)
          propertyList.unshift(row)
        else
          propertyList.push(row)

        if row.data_source_type == 'mls'
          mlsConfigSvc.getByIdCached(row.data_source_id)
          .then (mlsConfig) ->
            if mlsConfig
              row.mls_formal_name = mlsConfig.formal_name
              row.disclaimer_logo = mlsConfig.disclaimer_logo
              row.disclaimer_text = mlsConfig.disclaimer_text
              row.dcma_contact_name = mlsConfig.dcma_contact_name
              row.dcma_contact_address = mlsConfig.dcma_contact_address

      .then ->
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

  .then (result) ->
    logger.debug result
    for id, property of result
      logger.debug property
      result[id] = property.mls?[0] || property.county?[0]
    result

module.exports = {
  getDetail
  getDetails
}
