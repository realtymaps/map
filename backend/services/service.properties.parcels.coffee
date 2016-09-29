Promise = require 'bluebird'
logger = require('../config/logger').spawn('map:parcels')
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
sqlColumns = require './../utils/util.sql.columns.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'
tables = require '../config/tables'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'

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

getBaseParcelQueryByBounds = (bounds, limit, center) ->
  parcel = tables.finalized.parcel()
  query = parcel.select(parcel.raw("distinct on (geometry_center) #{sqlColumns.basicColumns.parcel}"))
  sqlHelpers.whereInBounds(query, 'geometry_raw', bounds)
  if center?
    query.select(query.raw("st_contains(geometry_raw, st_setsrid(st_makepoint(?,?), #{coordSys.UTM})) as map_center", [center.lng, center.lat]))
  query.where(active: true)
  query.limit(limit) if limit?

_getBaseParcelDataUnwrapped = (state, filters, doStream, limit) -> Promise.try () ->
  validation.validateAndTransform(filters, transforms)
  .then (filters) ->
    query = getBaseParcelQueryByBounds(filters.bounds, limit, filters.state?.map_position?.center)
    return query.stream() if doStream
    query

# pseudo-new implementation
getBaseParcelData = (state, filters) ->
  _getBaseParcelDataUnwrapped(state,filters, undefined, 500)
  .then (data) ->
    type: 'FeatureCollection'
    features: data

module.exports = {
  getBaseParcelQueryByBounds
  getBaseParcelData
}
