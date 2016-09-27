sqlHelpers = require '../utils/util.sql.helpers'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:cartodb')
cartodbConfig = require '../config/cartodb/cartodb'
cartodb = require 'cartodb'
tables = require '../config/tables'
CsvStringify = require('csv-stringify')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
fs = require 'fs'
moment = require 'moment'

csvStringifyFact = (opts) ->
  opts ?= {
    header: true
    formatters:
      date: (value) ->
        # override to get postgres sql time to work on cartodb side
        # otherwise csv-stringify defaults to bigInt / date.getTime()
        #2016-09-21 22:00:59.508668, example of time from psql csv
        moment.utc(value).format('YYYY-MM-DD HH:mm:ss.SSSSSS')
  }

  CsvStringify(opts)


shittyPromiseToPromise = (shitty) -> new Promise (resolve, reject) ->
  shitty.done resolve
  shitty.error reject


execSql = (sql) ->
  logger.debug sql

  if !sql?
    throw new new errorHandlingUtils.PartiallyHandledError 'sql must be defined'

  cartodbConfig()
  .then (config) ->
    sqlInst = new cartodb.SQL
      user: config.ACCOUNT
      api_key: config.API_KEY

    shittyPromiseToPromise(sqlInst.execute(sql))

###
  Public: Takes a stream of data and uploads the rows of concern to
  cartodb.

  NOTE: THIS IS THE IDEAL Solution to pump the raw stream to cartodb and not save it as a file

  TODO: https://github.com/CartoDB/cartodb-nodejs/issues/57

 - `stream`   The stream object {Stream}.
 - `fileName` The file name identifier on cartodb to save as {String}.

  Returns promise of void.
###
upload = ({stream, fileName}) -> Promise.try ->
  # main goal is to use a raw stream of data and pump it as a csv, without saving it on the file system
  fileName += '.csv'

  logger.debug -> "importing #{fileName}"

  cartodbConfig()
  .then (config) ->

    imprt = new cartodb.Import
      user: config.ACCOUNT
      api_key: config.API_KEY

    shittyPromiseToPromise(imprt.stream(
      stream.pipe(csvStringifyFact()),
      filename: fileName
      debug: true
    ))


saveFile = ({fileName, stream}) ->
  fileName += '.csv'

  logger.debug -> "saving csv to #{fileName}"

  s = stream.pipe(csvStringifyFact())
  .pipe fs.createWriteStream fileName

  new Promise (resolve, reject) ->
    s.once 'close', resolve
    s.once 'done', resolve
    s.once 'error', reject


uploadFile = (fileName) -> Promise.try ->
  # https://carto.com/docs/carto-engine/import-api/importing-geospatial-data/#supported-geospatial-data-formats
  # this method requres supported cartodb format files to exist on the fileSystem to then import
  cartodbConfig()
  .then (config) ->

    imprt = new cartodb.Import
      user: config.ACCOUNT
      api_key: config.API_KEY

    shittyPromiseToPromise(imprt.file(fileName))


fipsCodeQuery = (opts) ->
  if !opts?.fips_code?
    throw new Error('opts.fips_code required!')

  query = sqlHelpers.select(tables.finalized.parcel(), 'cartodb_parcel', false)
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

  query


module.exports = {
  execSql
  upload
  uploadFile
  saveFile
  fipsCodeQuery
  csvStringifyFact
}
