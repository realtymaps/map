db = require('../config/dbs').properties
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'
tables = require '../../config/tables'


transforms =
    bounds:
        transform: [
            validation.validators.string(minLength: 1)
            validation.validators.geohash
            validation.validators.array(minLength: 2)
        ]
        required: true

_tableName = tables.propertyData.parcel.tableName
_rootTableName = tables.propertyData.rootParcel.tableName

_getBaseParcelQuery = (tblName = _tableName) ->
    sqlHelpers.select(db.knex, 'parcel', false, 'distinct on (rm_property_id)')
    .from(tblName)

_getBaseParcelQueryByBounds = (bounds, limit) ->
    query = _getBaseParcelQuery()
    sqlHelpers.whereInBounds(query, 'geom_polys_raw', bounds)
    query.limit(limit) if limit?
    # logger.debug query.toString()
    query

_getBaseParcelDataUnwrapped = (state, filters, doStream, limit) -> Promise.try () ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
        query = _getBaseParcelQueryByBounds(filters.bounds, limit)
        return query.stream() if doStream
        query

_get = (rm_property_id, tblName = _tableName) ->
    throw "rm_property_id must be of type String" unless _.isString rm_property_id
    #nmccready - note this might not be unique enough, I think parcels has dupes
    db.knex.select().from(tblName)
    .where rm_property_id: rm_property_id

_upsert = (obj, insertCb, updateCb) ->
    _get(obj.rm_property_id, _rootTableName).then (rows) ->
        if rows?.length
            # logger.debug JSON.stringify(rows)
            return updateCb(rows[0])
        return insertCb(obj)

module.exports =
    getBaseParcelQuery: _getBaseParcelQuery
    getBaseParcelQueryByBounds: _getBaseParcelQueryByBounds
    getBaseParcelDataUnwrapped: _getBaseParcelDataUnwrapped
    # pseudo-new implementation
    getBaseParcelData: (state, filters) ->
        _getBaseParcelDataUnwrapped(state,filters, undefined, 500)
        .then (data) ->
            type: "FeatureCollection"
            features: data
    upsert: _upsert
