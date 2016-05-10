Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
{toLeafletMarker} = (require './../utils/crud/extensions/util.crud.extension.user').route

columnSets = ['filter', 'address', 'detail', 'all']

transforms =
  rm_prop_id_or_geom_json:
    input: ["rm_property_id", "geom_point_json"]
    transform: validators.pickFirst()
    required: true

  columns:
    transform: validators.choice(choices: columnSets)
    required: true

  rm_property_id:
    transform: any: [validators.string(minLength:1), validators.array()]

  geom_point_json:
    transform: [validators.object(),validators.geojson(toCrs:true)]


_getDetailByPropertyId = (queryParams) ->
  query = sqlHelpers.select(
    tables.property.combined()
    'new_all_explicit'  # queryParams.columns was used before, probably will be again
    null
    "#{tables.config.mls.tableName}.dcma_contact_name, #{tables.config.mls.tableName}.dcma_contact_address, #{tables.config.mls.tableName}.formal_name, ")
  .where
    active: true
    rm_property_id: queryParams.rm_property_id
  .leftOuterJoin("#{tables.config.mls.tableName}", () ->
    this.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")
  )

_getDetailByPropertyIds = (queryParams) ->
  query = sqlHelpers.select(
    tables.property.combined()
    'new_all_explicit'
    null
    "#{tables.config.mls.tableName}.dcma_contact_name, #{tables.config.mls.tableName}.dcma_contact_address, #{tables.config.mls.tableName}.formal_name, ")
  sqlHelpers.orWhereIn(query, 'rm_property_id', queryParams.rm_property_id)
  query.where(active: true)
  .leftOuterJoin("#{tables.config.mls.tableName}", () ->
    this.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")
  )

_getDetailByGeomPointJson = (queryParams) ->
  query = sqlHelpers.select(
    tables.property.combined()
    'new_all_explicit'
    null
    "#{tables.config.mls.tableName}.dcma_contact_name, #{tables.config.mls.tableName}.dcma_contact_address, #{tables.config.mls.tableName}.formal_name, ")
  sqlHelpers.whereIntersects(query, queryParams.geom_point_json, 'geometry_raw')
  query.where(active: true)
  .leftOuterJoin("#{tables.config.mls.tableName}", () ->
    this.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")
  )


module.exports =

  getDetail: (queryParams) -> Promise.try () ->
    validation.validateAndTransform(queryParams, transforms)
    .then (validRequest) ->

      if validRequest.rm_property_id?
        _getDetailByPropertyId(validRequest)
      else
        _getDetailByGeomPointJson(validRequest)
    .then (data=[]) ->

      result = { county: null, mls: null }
      for row in data
        result[row.data_source_type] ?= []
        result[row.data_source_type].push(row)
      result

  getDetails: (queryParams) ->
    Promise.try () ->
      if queryParams.rm_property_id?
        _getDetailByPropertyIds(queryParams)
      else
        []
    .then (data=[]) ->
      result = {}
      for row in data
        result[row.rm_property_id] ?= { county: null, mls: null }
        result[row.rm_property_id][row.data_source_type] ?= []
        result[row.rm_property_id][row.data_source_type].push(row)
      result
