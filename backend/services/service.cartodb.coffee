Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:cartodb')
cartodbSqlFact = require '../utils/util.cartodb.sql'
internals = require './service.cartodb.internals'
execAsync = Promise.promisify require('child_process').exec
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
require '../../common/extensions/lodash'
_ = require 'lodash'
parcelFetcher = require './service.parcels.fetcher.digimaps'


MAX_LINE_COUNT = 150000

###
  Public: Queries fipsCoded parcels to then upload to cartodb

  Returns the Promise(Array<tableName:String>)
###
upload = (fips_code, lineMaxCount = MAX_LINE_COUNT) -> Promise.try () ->
  cmds = internals.splitCommands(fipsCode: fips_code, lineCount:lineMaxCount)
  {wc} = cmds
  # NOTE:
  # can't implement below due to https://github.com/CartoDB/cartodb-nodejs/issues/57
  # stream = internals.fipsCodeQuery({fips_code}).stream()
  # internals.upload {stream, fileName: fips_code}

  fileName = "/tmp/#{fips_code.toString()}"

  toCSV {fips_code, fileName}
  .then () ->
    #NOTE: cartodb does have limits on file size uploads depending on Plans (un-documented)
    # PRO - import row limit of 500,000 and an import file size of 1.6GB
    execAsync(wc)
    .then (count) ->
      logger.debug -> "lineCount: #{count}"
      parseInt(count) < lineMaxCount
    .then (isLessThanMax) ->
      if isLessThanMax
        logger.debug -> "isLessThanMax: normal upload"
        return internals.uploadFile(fileName + ".csv").then (tableName) -> [tableName]


      logger.debug -> "is NOT isLessThanMax: split upload"
      internals.splitUpload(cmds)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new new errorHandlingUtils.PartiallyHandledError error, "uploadFile failed"

###
  Public: Utility function to export our parcel data of a specific
  fips_code to csv to easily push to cartodb:

 - `fileName`  Optional filename {string}
 - `fips_code` {string}.

  Returns promisfied exec function

  Reference: https://carto.com/docs/carto-engine/import-api/importing-geospatial-data/#csv

  Post usage:
  -- import / upload:
  `curl -v -F file=@/tmp/{fips_code or filename}.csv https://realtymaps.carto.com/api/v1/imports?api_key={YOUR_KEY}`
  -- verify import success:
  `curl -v "https://realtymaps.carto.com/api/v1/imports/item_queue_id?api_key={YOUR_KEY}"`

###
toCSV = ({fileName, fips_code, batch_id, rawEntity, select}) -> Promise.try () ->
  fileName ?= fips_code
  select ?= select = ['feature']

  logger.debug -> "fileName: #{fileName}, fips_code: #{fips_code}"
  logger.debug -> "batch_id: #{batch_id}" if batch_id
  logger.debug -> "rawEntity: #{JSON.stringify rawEntity}" if rawEntity

  stream = if !batch_id && !rawEntity
    internals.fipsCodeQuery({fips_code}).stream()
  else
    logger.debug -> 'getting raw'
    parcelFetcher.getRawParcelJsonStream({fips_code, batch_id, entity: rawEntity, select})

  internals.saveFile {stream, fileName}

###
Useful for comparing csv-stringfy to to fix problems.. so LEAVE this
###
toPsqlCSV = ({fileName, fips_code, batch_id, raw_entity, select }) -> Promise.try ->
  fileName ?= fips_code
  select ?= select = ['feature']

  subQuery = if !batch_id && !raw_entity
    internals.fipsCodeQuery({fips_code}).toString()
  else
    parcelFetcher.rawParcelQuery({fips_code, batch_id, entity: raw_entity, select}).toString()

  logger.debug -> subQuery
  query = "\"COPY (#{subQuery}) To '#{fileName}.csv' CSV HEADER;\""

  cmd = "psql -d realtymaps_main -c #{query}"

  execAsync(cmd)


#merge data to parcels cartodb table
synchronize = ({fipsCode, tableName, destinationTable}) -> Promise.try () ->
  cartodbSql = cartodbSqlFact(destinationTable)

  indexes({tableName, destinationTable})
  .then ->
    internals.execSql(cartodbSql.update({fipsCode, tableName}))
  .then ->
    internals.execSql(cartodbSql.insert({fipsCode, tableName}))
  .then ->
    internals.execSql(cartodbSql.delete({fipsCode, tableName}))
  .then ->
    internals.execSql(cartodbSql.drop({fipsCode, tableName}))


drop = ({fipsCode, tableName, destinationTable}) ->
  cartodbSql = cartodbSqlFact(destinationTable)
  internals.execSql(cartodbSql.drop({fipsCode, tableName}))


indexes = ({tableName, destinationTable}) ->
  cartodbSql = cartodbSqlFact(destinationTable)
  internals.execSql(cartodbSql.indexes({tableName}))

drop_indexes = ({tableName, destinationTable, idxName}) ->
  cartodbSql = cartodbSqlFact(destinationTable)
  internals.execSql(cartodbSql.drop_indexes({tableName, idxName}))


sql = (sqlStr) ->
  internals.execSql(sqlStr)


getByFipsCode = (opts) -> Promise.try () ->
  internals.fipsCodeQuery(opts)


syncDequeue = ({tableNames, fipsCode, batch_id, id}) ->
  if !Array.isArray(tableNames)
    tableNames = [tableNames]

  Promise.each tableNames, (tableName) ->
    logger.debug("@@@@@@@ synching #{tableName} @@@@@@@")
    synchronize({fipsCode, tableName})
  .then () ->
    logger.debug "dequeing: id: #{id}, batch_id: #{batch_id}"
    entity = _.extend {}, {fips_code: fipsCode, batch_id, id}
    entity = _.cleanObject entity

    tables.cartodb.syncQueue()
    .where(entity)
    .delete()



module.exports = {
  upload
  uploadFile: internals.uploadFile
  split: internals.split
  splitUpload: internals.splitUpload
  synchronize
  toCSV
  toPsqlCSV
  drop
  indexes
  drop_indexes
  sql
  getByFipsCode
  splitCommands: internals.splitCommands
  syncDequeue
  MAX_LINE_COUNT
}
