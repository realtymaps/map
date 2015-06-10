db = require('../config/dbs').properties
Parcel = require "../models/model.parcels"
sqlHelpers = require './../utils/util.sql.helpers.coffee'
_parcelTable = sqlHelpers.tableName(Parcel)
Promise = require "bluebird"
logger = require '../config/logger'
{CARTODB} = require '../config/config'
cartodb = require 'cartodb-api'
cartodbSql = require '../utils/util.cartodb.sql'


JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
mapboxUpload = require '../utils/util.mapbox'
fs = require 'fs'

_execCartodbSql = (sql) ->
    cartodb.sql
        apiKey: CARTODB.API_KEY
        sql:sql

_upload = (stream, fileName) -> Promise.try ->
    # writeStream = fs.createWriteStream './output.json'
    filteredStream =
        stream.pipe(geoJsonFormatter())

    # filteredStream.pipe(process.stdout) #uncomment to send to console
    # filteredStream.pipe(writeStream) #uncomment to write file

    new Promise (resolve, reject) ->
        filteredStream.on 'error', reject
        filteredStream.on 'end', ->
            logger.debug "stream length: #{byteLen}"
            logger.debug 'done processing stream'

            resolve Promise.all _.map MAPBOX.MAPS, (mapId) ->
                cartodb.upload
                    apiKey: CARTODB.API_KEY
                    stream: filteredStream
                    uploadFileName: fileName

_fipsCodeQuery = (opts) ->
    throw "opts.fipscode required!" unless opts?.fipscode?

    query =
    sqlHelpers.select(db.knex, 'cartodb_parcel', false, 'distinct on (rm_property_id)')
    .from _parcelTable
    .where fips_code:opts.fipscode
    .whereNotNull 'rm_property_id'
    .orderBy 'rm_property_id'

    if opts?.limit?
        query.limit(opts.limit)
    if opts?.start_rm_property_id?
        query.whereRaw("rm_property_id > '#{opts.start_rm_property_id}'")
    if opts?.nesw?
        # logger.debug opts.nesw
        query = sqlHelpers.whereInBounds(query, 'geom_polys_raw', opts.nesw)
    # logger.debug query.toString()
    query

_parcel =
    upload: (fipscode) ->
        _upload _fipsCodeQuery(fipscode: fipscode).stream(), fipsCode

    #merge data to parcels cartodb table
    synchronize: (fipsCode) -> Promise.try ->
        _execCartodbSql(cartodbSql.update(fipsCode))
        .then ->
            _execCartodbSql(cartodbSql.insert(fipsCode))
        .then ->
            _execCartodbSql(cartodbSql.delete(fipsCode))
        .then ->
            _execCartodbSql(cartodbSql.drop(fipsCode))

    getByFipsCode: (opts) ->
        _fipsCodeQuery(opts)

module.exports =

    parcel: _parcel
    restful:
        getByFipsCode: (opts) ->
            # logger.debug opts,true
            if !opts or !opts.api_key? or opts.api_key != CARTODB.API_KEY_TO_US
                throw 'UNAUTHORIZED'
            if !opts.fipscode?
                throw 'BADREQUEST'

            _parcel.getByFipsCode(opts)
        uploadParcel: (state, filters) -> Promise.try ->
            _parcel.uploadParcel(filters.fips_code)
