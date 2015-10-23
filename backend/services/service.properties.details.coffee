Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
{validators} = validation
sqlHelpers = require './../utils/util.sql.helpers'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
{property} = require '../config/tables'
{propertyDetails} = property
{crsFactory} = require '../../common/utils/enums/util.enums.map.coord_system'
{toLeafletMarker} = (require './../utils/crud/extensions/util.crud.extension.user').route
_  = require 'lodash'

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
    transform: validators.string(minLength: 1)

  geom_point_json:
    transform: [validators.string(minLength: 1, toObject: true),validators.object(),validators.geojson()]

_getDetailByPropertyId = (request) ->

  query = sqlHelpers.select(propertyDetails(), request.columns)
  .where(rm_property_id: request.rm_property_id)
  .limit(1)

  # logger.debug query.toString()
  query

_getDetailByGeomPointJson = (request) ->

  request.geom_point_json.crs = crsFactory()

  query = propertyDetails()
  sqlHelpers.select(query, request.columns, false, 'distinct on (rm_property_id)')
  sqlHelpers.whereIntersects(query, request.geom_point_json)
  query.limit(1)
  # logger.debug query.toString()
  query

module.exports =

  getDetail: (request) -> Promise.try () ->

    validation.validateAndTransform(request, _transforms).then (validRequest) ->

      if validRequest.rm_property_id?
        return _getDetailByPropertyId(validRequest)
      _getDetailByGeomPointJson(validRequest)

    .then (data) ->
      return data?[0]
    .then (data) ->
      if data?
        return toLeafletMarker data
      data
