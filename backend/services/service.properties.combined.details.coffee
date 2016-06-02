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
    'detail_with_disclaimer'  # queryParams.columns was used before, probably will be again
    null)
  .where
    active: true
    rm_property_id: queryParams.rm_property_id
  .leftOuterJoin("#{tables.config.mls.tableName}", () ->
    this.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")
  )
  if queryParams.fips_codes?
    sqlHelpers.whereIn(query, 'fips_code', queryParams.fips_codes)
  query

_getDetailByPropertyIds = (queryParams) ->
  query = sqlHelpers.select(
    tables.property.combined()
    'detail_with_disclaimer'
    null)
  sqlHelpers.orWhereIn(query, 'rm_property_id', queryParams.rm_property_id)
  query.where(active: true)
  .leftOuterJoin("#{tables.config.mls.tableName}", () ->
    this.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")
  )
  if queryParms.fips_codes?
    sqlHelpers.whereIn(query, 'fips_code', queryParams.fips_codes)
  query

_getDetailByGeomPointJson = (queryParams) ->
  query = sqlHelpers.select(
    tables.property.combined()
    'detail_with_disclaimer'
    null)
  sqlHelpers.whereIntersects(query, queryParams.geom_point_json, 'geometry_raw')
  query.where(active: true)
  .leftOuterJoin("#{tables.config.mls.tableName}", () ->
    this.on("#{tables.config.mls.tableName}.id", "#{tables.property.combined.tableName}.data_source_id")
  )
  if queryParams.fips_codes?
    sqlHelpers.whereIn(query, 'fips_code', queryParams.fips_codes)
  query

module.exports =

  getDetail: (req) -> Promise.try () ->
    queryParams = req.validBody
    validation.validateAndTransform(queryParams, transforms)
    .then (validRequest) ->
      if !req.user.is_superuser
        validRequest.fips_codes = req.user.fips_codes

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

  getDetails: (req) ->
    queryParams = req.validBody
    Promise.try () ->
      if !req.user.is_superuser
        queryParams.fips_codes = req.user.fips_codes

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
