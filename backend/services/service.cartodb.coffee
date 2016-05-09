require("chai").should()
sqlHelpers = require '../utils/util.sql.helpers'
Promise = require 'bluebird'
logger = require '../config/logger'
cartodbConfig = require '../config/cartodb/cartodb'
cartodb = require 'cartodb-api'
cartodbSql = require '../utils/util.cartodb.sql'
tables = require '../config/tables'

{geoJsonFormatter} = require '../utils/util.streams'


_execCartodbSql = (sql) ->
  cartodbConfig()
  .then (config) ->
    cartodb.sql
      apiKey: config.API_KEY
      sql:sql

_upload = (stream, fileName) -> Promise.try ->

  filteredStream = stream.pipe(geoJsonFormatter([
    'rm_property_id'
    'street_address_num'
    'geom_point_json'
    'passedFilters'
  ]))

  # writeStream = fs.createWriteStream './output.json'
  # filteredStream.pipe(process.stdout) #uncomment to send to console
  # filteredStream.pipe(writeStream) #uncomment to write file
  cartodbConfig()
  .then (config) ->
    new Promise (resolve, reject) ->
      filteredStream.on 'error', reject
      filteredStream.on 'end', ->
        logger.debug 'done processing stream'

        resolve cartodb.upload
          apiKey: config.API_KEY
          stream: filteredStream
          uploadFileName: fileName

_fipsCodeQuery = (opts) -> Promise.try () ->
  throw new Error('opts.fipscode required!') unless opts?.fipscode?
  query =
  sqlHelpers.select(tables.property.parcel(), 'cartodb_parcel', false)
  .where
    fips_code: opts.fipscode
    active: true
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
  upload: (fipsCode) ->
    _upload _fipsCodeQuery(fipscode: fipsCode).stream(), fipsCode

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
