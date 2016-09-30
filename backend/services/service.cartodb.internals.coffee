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
execAsync = Promise.promisify require('child_process').exec
lsAsync = Promise.promisify require('fs').readdir

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

  logger.debug -> query.toString()

  query

###
  Atomic creation of commands to execute. It is atomic in the sense that
  the majority of the commands name directories and files based on the current PID.
  This is to keep from file collisions.

 - `lineCount` number of lines to split a file {number}.
 - `fips_code/fipsCode`   fipsCode {string}.

  Returns a command object
###
splitCommands = ({lineCount, fipsCode, fips_code}) ->
  fipsCode = fipsCode || fips_code
  path = "/tmp/#{fipsCode}"
  dirname = "#{path}_#{process.pid}"
  origFile = "#{path}.csv"
  path = dirname

  wc: "wc -l #{origFile} | awk '{print $1}'" #aka line count
  split: "split -l #{lineCount} #{origFile} #{dirname}_"
  mkdir: "mkdir -p #{dirname}"
  mv: "mv #{dirname}_* #{dirname}"
  rename: "cd #{dirname};rename s/$/\.csv/ *"
  path: path
  dirname: dirname
  prependHeader: (brokenFileName) ->
    source = "#{dirname}/#{brokenFileName}"
    temp = "#{dirname}/#{brokenFileName}_tmp"
    """
    head -n 1 #{origFile} > #{temp};
    cat #{source} >> #{temp};
    mv #{temp} #{source}
    """


execSplit = (cmds) ->
  {split, mkdir, mv, rename, path, prependHeader} = cmds

  runCommand = (cmd) ->
    logger.debug -> cmd
    execAsync(cmd)

  runCommand(split)
  .then () ->
    runCommand(mkdir)
  .then () ->
    runCommand(mv)
  .then ()->
    lsAsync(path)
    .then (files) ->
      files.shift() #skip first as it already has the header
      Promise.each files, (f) ->
        prepend = prependHeader(f)
        runCommand(prepend)
  .then () ->
    runCommand(rename)
  .then () ->
    lsAsync(path)

splitUpload = (cmds) ->
  {dirname} = cmds
  tableNames = []

  execSplit(cmds)
  .then (filenames) ->
    # we can't use Promise.map because overall there should only be one upload going on per fips_code
    Promise.each filenames, (brokenFile) ->
      uploadFile("#{dirname}/#{brokenFile}")
      .then (tableName) ->
        tableNames.push tableName
    .then () ->
      tableNames

module.exports = {
  execSql
  upload
  uploadFile
  saveFile
  fipsCodeQuery
  csvStringifyFact
  splitCommands
  splitUpload
  split: execSplit
}
