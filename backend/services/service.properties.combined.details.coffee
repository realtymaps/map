logger = require('../config/logger').spawn('map:details:combined')
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
{getPermissions, queryPermissions, scrubPermissions} = require './service.properties.combined.filterSummary'
_ = require 'lodash'
mlsConfigSvc = require './service.mls_config'
Promise = require 'bluebird'
moment = require 'moment'

_propertyQuery = ({queryParams, profile, limit}) ->
  getPermissions(profile)
  .then (permissions) ->
    logger.debug permissions

    query = sqlHelpers.select(tables.finalized.combined(), queryParams.columns)
    .leftOuterJoin "#{tables.config.mls.tableName}", ->
      @.on("#{tables.config.mls.tableName}.id", "#{tables.finalized.combined.tableName}.data_source_id")

    queryPermissions(query, permissions)

    # Remainder of query is grouped so we get SELECT .. WHERE (permissions) AND (filters)
    query.where ->
      @where(active: true)

      if queryParams.rm_property_id?
        sqlHelpers.whereIn(@, 'rm_property_id', queryParams.rm_property_id)
      else if queryParams.geometry_center?
        sqlHelpers.whereIntersects(@, queryParams.geometry_center, 'geometry_raw')

    logger.debug query.toString()

    query.then (data = []) ->
      # Prune subscriber groups and owner info where appropriate
      scrubPermissions(data, permissions)

      return data

# Retrieve a single property by rm_property_id OR geometry_center
getProperty = ({query, profile}) ->
  validation.validateAndTransform query,
    rm_property_id_or_geometry_center:
      input: ["rm_property_id", "geometry_center"]
      transform: validators.pickFirst()
      required: true

    rm_property_id:
      transform: validators.string(minLength: 1)

    geometry_center:
      transform: [validators.object(), validators.geojson(toCrs: true)]

    columns:
      transform: validators.choice(choices: ['filter', 'address', 'all', 'id'])
      required: true

  .then (queryParams) ->
    _propertyQuery({queryParams, profile})

  .then (data) ->
    result = {}

    Promise.map data, (row) ->
      result[row.rm_property_id] ?= { county: null, mls: null }
      result[row.rm_property_id][row.data_source_type] ?= []
      result[row.rm_property_id][row.data_source_type].push(row)

      if row.data_source_type == 'mls'
        mlsConfigSvc.getByIdCached(row.data_source_id)
        .then (mlsConfig) ->
          if mlsConfig
            row.mls_formal_name = mlsConfig.formal_name
            row.disclaimer_logo = mlsConfig.disclaimer_logo
            row.disclaimer_text = mlsConfig.disclaimer_text
            row.dmca_contact_name = mlsConfig.dmca_contact_name
            row.dmca_contact_address = mlsConfig.dmca_contact_address

    .then () ->
      _.map(result)[0]

# Retrieve a set of properties by rm_property_id (filter data only)
getProperties = ({query, profile}) ->
  validation.validateAndTransform query,
    rm_property_id:
      transform: validators.array()
      required: true

  .then (queryParams) ->
    queryParams.columns = 'filter'
    _propertyQuery({queryParams, profile})

  .then (data) ->
    result = {}

    Promise.map data, (row) ->
      existing = result[row.rm_property_id]
      if !existing || (row.data_source_type == 'mls' && existing.data_source_type != 'mls') ||
          (row.data_source_type == 'mls' && existing.data_source_type != 'mls' &&
            moment(existing.up_to_date).isBefore(row.up_to_date))

        result[row.rm_property_id] = row

    .then () ->
      _.map(result)

module.exports = {
  getProperty
  getProperties
}
