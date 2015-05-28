db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
Promise = require "bluebird"
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'

transforms =
    bounds:
        transform: [
            validation.validators.string(minLength: 1)
            validation.validators.geohash
            validation.validators.array(minLength: 2)
        ]
        required: true

_tableName = sqlHelpers.tableName(Parcel)
_rootTableName = 'parcels'

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
    #nmccready - note this might not be unqiue enough, I think parcels has dupes
    _getBaseParcelQuery()
    .where rm_property_id: rm_property_id

_upsert = (obj, insertCb, updateCb) ->
    _get(obj, _rootTableName).then (row) ->
        return insertCb(obj) if !row || !_.keys(row).length
        updateCb(obj)

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
    rootDb: ->
        db.knex(_rootTableName)
