# this is where common task-related code should go that isn't job-queue-infrastructure related or generic enough to go
# in a general util module

_ = require 'lodash'
jobQueue = require '../util.jobQueue'
Promise = require 'bluebird'
rets = require 'rets-promise'
Encryptor = require '../util.encryptor.coffee'
config = require '../../config/config'
VError = require 'verror'
dbs = require '../../config/dbs'
moment = require('moment')
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require '../util.streams'

encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)
knex = jobQueue.knex

isNewError = (err) ->
  return err instanceof VError

tables =
  dataLoadHistory: 'data_load_history'

getLastSuccessStartTime = (taskName) ->
  knex
  .table(jobQueue.tables.taskHistory)
  .max('started AS last_success')
  .where
    name: taskName
    current: false
    status: 'success'
  .then () ->
    result?[0]?.last_success || new Date(0)
    
loadRetsTableUpdates = (subtask, options) ->
  rawTableName = "raw_#{subtask.task_name}_#{options.rawTableSuffix}__#{subtask.batch_id}"
  retsClient = new rets.Client
    loginUrl: subtask.task_data.url
    username: subtask.task_data.login
    password: encryptor.decrypt(subtask.task_data.password)
  retsClient.login()
  .catch isNewError, (error) ->
    throw VError(error, "login to RETS server failed")
  .then () ->
    retsClient.metadata.getTable(options.retsDbName, options.retsTableName)
  .then (tableInfo) ->
    _.pluck tableInfo.Fields, 'SystemName'
  .catch isNewError, (error) ->
    throw VError(error, "failed to determine table fields")
  .then (fields) ->
    dbs.properties.knex
    .insert
        data_source_id: options.retsId
        data_source_type: 'mls'
        batch_id: subtask.batch_id
        raw_table_name: rawTableName
    .into(tables.dataLoadHistory)
    .then () ->
      dbs.properties.knex.schema.createTable rawTableName, (table) ->
        table.increments('rm_raw_id').notNullable()
        table.boolean('rm_valid')
        _.forEach fields, (field) ->
          table.text(field)
    .catch isNewError, (error) ->
      throw VError(error, "failed to create temp table: #{rawTableName}")
    .then () ->
      getLastSuccessStartTime(subtask.task_name)
    .then (lastSuccess) ->
      retsClient.search.query(options.retsDbName, options.retsTableName, moment.utc(lastSuccess).format(options.retsQueryTemplate))
    .catch isNewError, (error) ->
      if error.replyCode == "20201"
        # code for 0 results
        return []
      #else if error.replyCode == "20208"
      # code for too many results, must manually paginate
      throw VError(error, "failed to query RETS system")
    .then (results) ->
      pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
      pgConnect = Promise.promisify(pgClient.connect, pgClient)
      pgConnect()
      .then () -> new Promise (resolve, reject) ->
        rawDataStream = pgClient.query(copyStream.from("COPY #{rawTableName} (\"#{fields.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8')"))
        rawDataStream.on('finish', resolve)
        rawDataStream.on('error', reject)
        from(results)
        .pipe(utilStreams.objectsToPgText(fields))
        .pipe(rawDataStream)
      .finally () ->
        pgClient.end()
    .catch isNewError, (error) ->
      throw VError(error, "failed to stream raw data to temp table: #{rawTableName}")
  .finally () ->
    retsClient.logout()

    
module.exports =
  tables: tables
  getLastSuccessStartTime: getLastSuccessStartTime
  loadRetsTableUpdates: loadRetsTableUpdates
 