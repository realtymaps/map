sqlHelpers = require '../utils/util.sql.helpers'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:cartodb')
cartodbConfig = require '../config/cartodb/cartodb'
cartodb = require 'cartodb-api'
cartodbSql = require '../utils/util.cartodb.sql'
tables = require '../config/tables'

{geoJsonFormatter} = require '../utils/util.streams'


_execCartodbSql = (sql) ->
  cartodbConfig()
  .then (config) ->
    cartodb.sql
      account: config.ACCOUNT
      apiKey: config.API_KEY
      sql:sql

_upload = (stream, fileName) -> Promise.try ->

  filteredStream = stream.pipe(geoJsonFormatter([
    'rm_property_id'
    'street_address_num'
    'geometry_center'
    'passedFilters'
  ]))

  # writeStream = fs.createWriteStream './output.json'
  # filteredStream.pipe(process.stdout) #uncomment to send to console
  # filteredStream.pipe(writeStream) #uncomment to write file
  cartodbConfig()
  .then (config) ->
    cartodb.upload
      account: config.ACCOUNT
      apiKey: config.API_KEY
      stream: filteredStream
      uploadFileName: fileName

_fipsCodeQuery = (opts) ->
  if !opts?.fips_code?
    throw new Error('opts.fips_code required!')
  query =
  sqlHelpers.select(tables.finalized.parcel(), 'cartodb_parcel', false)
  .where {
    fips_code: opts.fips_code
    active: true
  }
  .whereNotNull 'rm_property_id'
  .orderBy 'rm_property_id'

  if opts?.limit?
    query.limit(opts.limit)
  if opts?.start_rm_property_id?
    query.whereRaw("rm_property_id > '#{opts.start_rm_property_id}'")
  if opts?.nesw?
    # logger.debug opts.nesw
    query = sqlHelpers.whereInBounds(query, 'geometry_raw', opts.nesw)
  # logger.debug query.toString()
  query

parcel =
  upload: (fips_code) -> Promise.try () ->
    _upload _fipsCodeQuery({fips_code}).stream(), fips_code

  #merge data to parcels cartodb table
  synchronize: (fipsCode) -> Promise.try ->
    _execCartodbSql(cartodbSql.update(fipsCode))
    .then ->
      _execCartodbSql(cartodbSql.insert(fipsCode))
    .then ->
      _execCartodbSql(cartodbSql.delete(fipsCode))
    .then ->
      _execCartodbSql(cartodbSql.drop(fipsCode))

  getByFipsCode: (opts) -> Promise.try () ->
    _fipsCodeQuery(opts)

module.exports =

  parcel: parcel
  restful:
    getByFipsCode: (opts) ->
      # logger.debug opts,true
      cartodbConfig()
      .then (config) ->
        if opts?.api_key != config.API_KEY_TO_US
          throw new Error('UNAUTHORIZED')
        if !opts.fipscode?
          throw new Error('BADREQUEST')
      .then () ->
        parcel.getByFipsCode(opts)
    uploadParcel: (state, filters) -> Promise.try ->
      parcel.uploadParcel(filters.fips_code)
