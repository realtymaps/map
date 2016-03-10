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
  sqlHelpers.select(tables.property.combined(), 'new_all') # queryParams.columns was used before, probably will be again
  .where
    active: true
    rm_property_id: queryParams.rm_property_id

_getDetailByPropertyIds = (queryParams) ->
  query = sqlHelpers.select(tables.property.combined(), 'new_all')
  sqlHelpers.orWhereIn(query, 'rm_property_id', queryParams.rm_property_id)
  query.where(active: true)


_getDetailByGeomPointJson = (queryParams) ->
  query = tables.property.combined()
  sqlHelpers.select(query, 'new_all')
  sqlHelpers.whereIntersects(query, queryParams.geom_point_json, 'geometry_raw')
  query.where(active: true)


module.exports =

  getDetail: (queryParams) -> Promise.try () ->
    validation.validateAndTransform(queryParams, transforms).then (validRequest) ->
      if validRequest.rm_property_id?
        _getDetailByPropertyId(validRequest)
      else
        _getDetailByGeomPointJson(validRequest)
    .then (data) ->
      return data?[0]
    .then (data) ->
      if data?
        return toLeafletMarker data
      data

  getDetails: (queryParams) -> Promise.try () ->
    if queryParams.rm_property_id?
      _getDetailByPropertyIds(queryParams)
    else
      []
