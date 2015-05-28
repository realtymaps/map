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
jobQueue = require './util.jobQueue'


encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)


_streamArrayToDbTable = (objects, tableName, fields) ->
  # stream the results into a COPY FROM query; too bad we currently have to load the whole response into memory
  # first.  Eventually, we can rewrite the rets-promise client to use hyperquest and a streaming xml parser
  # like xml-stream or xml-object-stream, and then we can make this fully streaming (more performant)
  pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
  pgConnect = Promise.promisify(pgClient.connect, pgClient)
  pgConnect()
  .then () -> new Promise (resolve, reject) ->
    rawDataStream = pgClient.query(copyStream.from("COPY #{tableName} (\"#{Object.keys(fields.text).concat(Object.keys(fields.json)).join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8')"))
    rawDataStream.on('finish', resolve)
    rawDataStream.on('error', reject)
    # stream from array to object serializer stream to COPY FROM
    from(objects)
    .pipe(utilStreams.objectsToPgText(_.mapValues(fields.text, 'SystemName'), _.mapValues(fields.json, 'SystemName')))
    .pipe(rawDataStream)
  .finally () ->
    # always disconnect the db client when we're done
    pgClient.end()
  .then () ->
    return objects.length


# loads all records from a given RETS table that have changed since the last successful run of the task
loadRetsTableUpdates = (subtask, options) ->
  rawTableName = taskHelpers.getRawTableName subtask, options.rawTableSuffix
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
    fields =
      text: {}
      json: {}
    for field in tableInfo.Fields
      if field.Interpretation == 'LookupMulti'
        fields.json[field.LongName] = field
      else
        fields.text[field.LongName] = field
    return fields
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to determine table fields")
  .then (fields) ->
    taskHelpers.createDataHistoryEntry
      data_source_id: options.retsId
      data_source_type: 'mls'
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    .then () ->
      taskHelpers.createRawTempTable(rawTableName, Object.keys(fields.text), Object.keys(fields.json))
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "failed to create temp table: #{rawTableName}")
    .then () ->
      # figure out when we last got updates from this table
      taskHelpers.getLastStartTime(subtask.task_name)
    .then (lastSuccess) ->
      now = new Date()
      if now.getTime() - lastSuccess.getTime() > 24*60*60*1000 || now.getDate() != lastSuccess.getDate()
        # if more than a day has elapsed or we've crossed a calendar date boundary, refresh everything and handle deletes
        subtaskStep3Promise = jobQueue.getSubtaskConfig(jobQueue.knex, subtask.batch_id, subtask.task_data, 'markDeleted', subtask.task_name)
        subtaskStep5Promise = jobQueue.getSubtaskConfig(jobQueue.knex, subtask.batch_id, subtask.task_data, 'removeExtraRows', subtask.task_name)
        Promise.join(subtaskStep3Promise, subtaskStep5Promise)
        .then (subtaskStep3, subtaskStep5) ->
          queueStep3 = jobQueue.queueSubtask(jobQueue.knex, subtask.batch_id, subtask.task_data, subtaskStep3)
          queueStep5 = jobQueue.queueSubtask(jobQueue.knex, subtask.batch_id, subtask.task_data, subtaskStep5)
          Promise.join(queueStep3, queueStep5)
        .then () ->
          return new Date(0)
      else
        return lastSuccess
    .then (refreshThreshold) ->
      # query for everything changed since then
      retsClient.search.query(options.retsDbName, options.retsTableName, moment.utc(refreshThreshold).format(options.retsQueryTemplate))
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

    
# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) ->
  Promise.try () ->
    rawTableName = taskHelpers.getRawTableName subtask, options.rawTableSuffix
    rowsPromise = dbs.properties.knex(rawTableName)
    .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
    validationPromise = jobQueue.knex(taskHelpers.tables.dataNormalizationConfig)
    .where(data_source_id: options.dataSourceId)
    .then (validations=[]) ->
      validationMap = {}
      for validation in validations
        validationMap[validation.output_group] ?= {}
        validationMap[validation.output_group][validation.output_field] = validation
      validationMap
    Promise.join(rowsPromise, validationPromise)
  .then (rows, validation) ->
    Promise.map rows, (row) ->
      normalized =
        batch_id: subtask.batch_id
  

module.exports =
  loadRetsTableUpdates: loadRetsTableUpdates
  normalizeData: normalizeData
