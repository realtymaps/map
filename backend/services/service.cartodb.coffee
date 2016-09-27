Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:cartodb')
cartodbSqlFact = require '../utils/util.cartodb.sql'
internals = require './service.cartodb.internals'
exec = require('child_process').exec
###
  Public: Queries fipsCoded parcels to then upload to cartodb

  Returns the Promise(tableName)
###
upload = (fips_code) -> Promise.try () ->
  # NOTE:
  # can't implement below due to https://github.com/CartoDB/cartodb-nodejs/issues/57
  # stream = internals.fipsCodeQuery({fips_code}).stream()
  # internals.upload {stream, fileName: fips_code}

  fileName = "/tmp/#{fips_code.toString()}"

  toCSV {fips_code, fileName}
  .then () ->
    #NOTE: cartodb does have limits on file size uploads depending on Plans (un-documented)

    # PRO - import row limit of 500,000 and an import file size of 1.6GB
    # Therefore using linux / split may make it much easier to split this across
    # EXAMPLE: `split -l 1000 /tmp/12047.csv new`
    # http://stackoverflow.com/questions/20721120/how-to-split-csv-files-as-per-number-of-rows-specified
    internals.uploadFile(fileName + ".csv")

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
toCSV = ({fileName, fips_code}) -> Promise.try () ->
  fileName ?= fips_code

  logger.debug "fileName: #{fileName}, fips_code: #{fips_code}"

  internals.saveFile {
    stream: internals.fipsCodeQuery({fips_code}).stream()
    fileName
  }

###
Useful for comparing csv-stringfy to to fix problems.. so LEAVE this
###
toPsqlCSV = ({fileName, fips_code}) -> Promise.try ->
  fileName ?= fips_code

  subQuery = internals.fipsCodeQuery({fips_code}).toString()

  query = "\"COPY (#{subQuery}) To '#{fileName}.csv' CSV HEADER;\""

  cmd = "psql -d realtymaps_main -c #{query}"

  execAsync = Promise.promisify exec

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

sql = (sqlStr) ->
  internals.execSql(sqlStr)

getByFipsCode = (opts) -> Promise.try () ->
  internals.fipsCodeQuery(opts)


module.exports = {
  upload
  uploadFile: internals.uploadFile
  synchronize
  toCSV
  toPsqlCSV
  drop
  indexes
  sql
  getByFipsCode
}
