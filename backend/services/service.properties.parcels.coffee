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


_getBaseParcelQueryByBounds = (bounds, limit) ->
  query = sqlHelpers.select(tables.finalized.parcel(), 'parcel', false)
  sqlHelpers.whereInBounds(query, 'geometry_raw', bounds)
  query.where(active: true)
  query.limit(limit) if limit?

_getBaseParcelDataUnwrapped = (state, filters, doStream, limit) -> Promise.try () ->
  validation.validateAndTransform(filters, transforms)
  .then (filters) ->
    query = _getBaseParcelQueryByBounds(filters.bounds, limit)
    return query.stream() if doStream
    query

_upsert = (obj, insertCb, updateCb) ->
  throw new Error('rm_property_id must be of type String') unless _.isString obj.rm_property_id
  #nmccready - note this might not be unique enough, I think parcels has dupes
  # TODO: this must be dead code, safe to delete?
  tables.property.rootParcel()
  .where rm_property_id: obj.rm_property_id
  .then (rows) ->
    if rows?.length
      # logger.debug JSON.stringify(rows)
      return updateCb(rows[0])
    return insertCb(obj)

module.exports =
  getBaseParcelQueryByBounds: _getBaseParcelQueryByBounds
  getBaseParcelDataUnwrapped: _getBaseParcelDataUnwrapped
  # pseudo-new implementation
  getBaseParcelData: (state, filters) ->
    _getBaseParcelDataUnwrapped(state,filters, undefined, 500)
    .then (data) ->
      type: 'FeatureCollection'
      features: data
  upsert: _upsert
