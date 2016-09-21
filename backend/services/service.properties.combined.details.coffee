logger = require('../config/logger').spawn('map:details:combined')
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
dbs = require '../config/dbs'
{getPermissions, queryPermissions, scrubPermissions} = require './service.properties.combined.filterSummary'
_ = require 'lodash'
mlsConfigSvc = require './service.mls_config'
Promise = require 'bluebird'
moment = require 'moment'
transforms = require('../utils/transforms/transforms.properties').detail

_propertyQuery = ({queryParams, profile, limit}) ->
  getPermissions(profile)
  .then (permissions) ->
    logger.debug permissions

    query = sqlHelpers.select(tables.finalized.combined(), queryParams.columns)
    .leftOuterJoin("#{tables.config.mls.tableName}",
      "#{tables.config.mls.tableName}.id",
      "#{tables.finalized.combined.tableName}.data_source_id")
    .leftOuterJoin(tables.finalized.photo.tableName,
      "#{tables.finalized.combined.tableName}.data_source_uuid",
      "#{tables.finalized.photo.tableName}.data_source_uuid")

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

_queryNotes = ({rm_property_id, project_id}) ->
  query = tables.user.notes()
  .select(
    "#{tables.user.notes.tableName}.id",
    "#{tables.user.notes.tableName}.auth_user_id",
    "#{tables.user.notes.tableName}.rm_inserted_time",
    "rm_property_id",
    'project_id',
    'text',
    'first_name',
    'last_name',
    'email',
  )
  .select(dbs.raw('main', "geometry_center->'coordinates' as coordinates"))
  .innerJoin(tables.auth.user.tableName,
    "#{tables.auth.user.tableName}.id",
    "#{tables.user.notes.tableName}.auth_user_id")
  .where {
    rm_property_id
    project_id
  }

  logger.debug () -> query.toString()
  query.then (notes) ->
    for n in notes
      n.text = decodeURIComponent(n.text)
    notes


# Retrieve a single property by rm_property_id OR geometry_center
getProperty = ({query, profile}) ->
  validation.validateAndTransform query, transforms.property
  .then (queryParams) ->
    _propertyQuery({queryParams, profile})
  .then (data) ->
    result = {}

    Promise.map data, (row) ->
      result[row.rm_property_id] ?= { county: null, mls: null }
      result[row.rm_property_id][row.data_source_type] ?= []
      result[row.rm_property_id][row.data_source_type].push(row)

      if row.data_source_type == 'mls' && row.data_source_id?
        mlsConfigSvc.getByIdCached(row.data_source_id)
        .then (mlsConfig) ->
          if mlsConfig
            row.mls_formal_name = mlsConfig.formal_name
            row.disclaimer_logo = mlsConfig.disclaimer_logo
            row.disclaimer_text = mlsConfig.disclaimer_text
            row.dmca_contact_name = mlsConfig.dmca_contact_name
            row.dmca_contact_address = mlsConfig.dmca_contact_address
      _queryNotes {rm_property_id: row.rm_property_id, project_id: profile.project_id}
      .then (notes) ->
        if notes.length
          logger.debug "@@@@ NOTES @@@@"
          logger.debug () -> notes
          result[row.rm_property_id].notes = notes
    .then () ->
      _.map(result)[0]

# Retrieve a set of properties by rm_property_id (filter data only)
getProperties = ({query, profile}) ->
  validation.validateAndTransform query, transforms.properties
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
