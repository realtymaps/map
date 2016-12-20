Promise = require 'bluebird'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('service:properties:parcels')
# coffeelint: enable=check_scope
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
sqlColumns = require './../utils/util.sql.columns.coffee'
tables = require '../config/tables'


transforms =
  bounds:
    transform: [
      validation.validators.string(minLength: 1)
      validation.validators.geohash
      validation.validators.array(minLength: 2)
    ]
    required: true
  state:
    map_position:
      center: validation.validators.object()

getBaseParcelQueryByBounds = ({bounds, limit}) ->
  parcel = tables.finalized.parcel()
  query = parcel.select(parcel.raw("distinct on (geometry_center) #{sqlColumns.basicColumns.parcel}"))
  sqlHelpers.whereInBounds(query, 'geometry_raw', bounds)
  # if center?
  #   query.select(query.raw("st_contains(geometry_raw, st_setsrid(st_makepoint(?,?), #{coordSys.UTM})) as map_center", [center.lng, center.lat]))
  query.limit(limit) if limit?

_getBaseParcelDataUnwrapped = ({filters, doStream, limit}) -> Promise.try () ->
  validation.validateAndTransform(filters, transforms)
  .then (filters) ->
    query = getBaseParcelQueryByBounds({bounds: filters.bounds, limit})
    return query.stream() if doStream
    query

# pseudo-new implementation
getBaseParcelData = (state, filters) ->
  _getBaseParcelDataUnwrapped({filters, limit: 500})
  .then (data) ->
    type: 'FeatureCollection'
    features: data

module.exports = {
  getBaseParcelQueryByBounds
  getBaseParcelData
}
