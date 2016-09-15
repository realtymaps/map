Promise = require 'bluebird'
logger = require('../config/logger').spawn('map:parcels')
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'
tables = require '../config/tables'


transforms =
  bounds:
    transform: [
      validation.validators.string(minLength: 1)
      validation.validators.geohash
      validation.validators.array(minLength: 2)
    ]
    required: true


getBaseParcelQueryByBounds = (bounds, limit) ->
  query = sqlHelpers.select(tables.finalized.parcel(), 'parcel', false)
  sqlHelpers.whereInBounds(query, 'geometry_raw', bounds)
  query.where(active: true)
  query.limit(limit) if limit?

_getBaseParcelDataUnwrapped = (state, filters, doStream, limit) -> Promise.try () ->
  validation.validateAndTransform(filters, transforms)
  .then (filters) ->
    query = getBaseParcelQueryByBounds(filters.bounds, limit)
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
