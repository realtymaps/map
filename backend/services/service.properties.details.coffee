Promise = require 'bluebird'
logger = require('../config/logger').spawn('map:details')
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
{property} = require '../config/tables'
{propertyDetails} = property
{toLeafletMarker} = (require './../utils/crud/extensions/util.crud.extension.user').route

columnSets = ['filter', 'address', 'detail', 'all']

_transforms =
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

  query = sqlHelpers.select(propertyDetails(), queryParams.columns)
  .where(rm_property_id: queryParams.rm_property_id)
  .limit(1)

  # logger.debug query.toString()
  query

_getDetailByPropertyIds = (queryParams) ->

  query = sqlHelpers.select(propertyDetails(), 'filter')
  sqlHelpers.orWhereIn(query, 'rm_property_id', queryParams.rm_property_id)

  # logger.debug query.toString()
  query

_getDetailByGeomPointJson = (queryParams) ->
  query = propertyDetails()
  sqlHelpers.select(query, queryParams.columns, false, 'distinct on (rm_property_id)')
  sqlHelpers.whereIntersects(query, queryParams.geom_point_json)
  query.limit(1)
  # logger.debug query.toString()
  query

module.exports =

  getDetail: (queryParams) -> Promise.try () ->

    validation.validateAndTransform(queryParams, _transforms).then (validRequest) ->

      if validRequest.rm_property_id?
        return _getDetailByPropertyId(validRequest)
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
