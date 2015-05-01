_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require '../util.encryptor'
rets = require 'rets-promise'
Encryptor = require '../util.encryptor'
moment = require('moment')
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require '../util.streams'
dbs = require '../../config/dbs'
config = require '../../config/config'
taskHelpers = require './util.taskHelpers'


encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)


_streamArrayToDbTable = (objects, tableName, fields) ->
  # stream the results into a COPY FROM query; too bad we currently have to load the whole response into memory
  # first.  Eventually, we can rewrite the rets-promise client to use hyperquest and a streaming xml parser
  # like xml-stream or xml-object-stream, and then we can make this fully streaming (more performant)
  pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
  pgConnect = Promise.promisify(pgClient.connect, pgClient)
  pgConnect()
  .then () -> new Promise (resolve, reject) ->
    rawDataStream = pgClient.query(copyStream.from("COPY #{tableName} (\"#{fields.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8')"))
    rawDataStream.on('finish', resolve)
    rawDataStream.on('error', reject)
    # stream from array to object serializer stream to COPY FROM
    from(objects)
    .pipe(utilStreams.objectsToPgText(fields))
    .pipe(rawDataStream)
  .finally () ->
    # always disconnect the db client when we're done
    pgClient.end()


# loads all records from a given RETS table that have changed since the last successful run of the task
loadRetsTableUpdates = (subtask, options) ->
  rawTableName = "raw_#{subtask.task_name}_#{options.rawTableSuffix}__#{subtask.batch_id}"
  retsClient = new rets.Client
    loginUrl: subtask.task_data.url
    username: subtask.task_data.login
    password: encryptor.decrypt(subtask.task_data.password)
  retsClient.login()
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "login to RETS server failed")
  .then () ->
    # get info about the fields available in the table
    retsClient.metadata.getTable(options.retsDbName, options.retsTableName)
  .then (tableInfo) ->
    _.pluck tableInfo.Fields, 'SystemName'
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to determine table fields")
  .then (fields) ->
    taskHelpers.createDataHistoryEntry
      data_source_id: options.retsId
      data_source_type: 'mls'
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    .then () ->
      taskHelpers.createRawTempTable(rawTableName, fields)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "failed to create temp table: #{rawTableName}")
    .then () ->
      # figure out when we last got updates from this table
      taskHelpers.getLastSuccessStartTime(subtask.task_name)
    .then (lastSuccess) ->
      # query for everything changed since then
      retsClient.search.query(options.retsDbName, options.retsTableName, moment.utc(lastSuccess).format(options.retsQueryTemplate))
    .catch isUnhandled, (error) ->
      if error.replyCode == "20201"
        # code for 0 results, not really an error (DMQL is a clunky language)
        return []
      # TODO: else if error.replyCode == "20208"
      # code for too many results, must manually paginate or something to get all the data
      throw new PartiallyHandledError(error, "failed to query RETS system")
    .then (results) ->
      _streamArrayToDbTable(results, rawTableName, fields)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
  .finally () ->
    # always log out the RETS client when we're done
    retsClient.logout()


module.exports =
  loadRetsTableUpdates: loadRetsTableUpdates
