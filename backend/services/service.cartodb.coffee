db = require('../config/dbs').properties
sqlHelpers = require '../utils/util.sql.helpers'
Promise = require 'bluebird'
logger = require '../config/logger'
{CARTODB} = require '../config/config'
cartodb = require 'cartodb-api'
cartodbSql = require '../utils/util.cartodb.sql'
tables = require '../config/tables'


JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
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
  throw new Error('opts.fipscode required!') unless opts?.fipscode?
  query =
  sqlHelpers.select(tables.propertyData.parcel(), 'cartodb_parcel', false, 'distinct on (rm_property_id)')
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

parcel =
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

  parcel: parcel
  restful:
    getByFipsCode: (opts) ->
      # logger.debug opts,true
      if !opts or !opts.api_key? or opts.api_key != CARTODB.API_KEY_TO_US
        throw new Error('UNAUTHORIZED')
      if !opts.fipscode?
        throw new Error('BADREQUEST')

      parcel.getByFipsCode(opts)
    uploadParcel: (state, filters) -> Promise.try ->
      parcel.uploadParcel(filters.fips_code)
