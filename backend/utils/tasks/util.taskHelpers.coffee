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

# determines the start of the last time a task successfully ran, or defaults to the Epoch (Jan 1, 1970) if
# there are no successful runs
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
    
# loads all records from a given RETS table that have changed since the last successful run of the task
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
    # get info about the fields available in the table
    retsClient.metadata.getTable(options.retsDbName, options.retsTableName)
  .then (tableInfo) ->
    _.pluck tableInfo.Fields, 'SystemName'
  .catch isNewError, (error) ->
    throw VError(error, "failed to determine table fields")
  .then (fields) ->
    # insert a new entry into the data load history table -- this will be used for the raw table cleanup task, as
    # well as monitoring for problems with row parsing/validation
    dbs.properties.knex
    .insert
        data_source_id: options.retsId
        data_source_type: 'mls'
        batch_id: subtask.batch_id
        raw_table_name: rawTableName
    .into(tables.dataLoadHistory)
    .then () ->
      # create a temp table to store this data
      dbs.properties.knex.schema.createTable rawTableName, (table) ->
        table.increments('rm_raw_id').notNullable()
        table.boolean('rm_valid')
        _.forEach fields, (field) ->
          table.text(field)
    .catch isNewError, (error) ->
      throw VError(error, "failed to create temp table: #{rawTableName}")
    .then () ->
      # figure out when we last got updates from this table
      getLastSuccessStartTime(subtask.task_name)
    .then (lastSuccess) ->
      # query for everything changed since then
      retsClient.search.query(options.retsDbName, options.retsTableName, moment.utc(lastSuccess).format(options.retsQueryTemplate))
    .catch isNewError, (error) ->
      if error.replyCode == "20201"
        # code for 0 results, not really an error (DMQL is a clunky language)
        return []
      # TODO: else if error.replyCode == "20208"
      # code for too many results, must manually paginate or something to get all the data
      throw VError(error, "failed to query RETS system")
    .then (results) ->
      # stream the results into a COPY FROM query; too bad we currently have to load the whole response into memory
      # first.  Eventually, we can rewrite the rets-promise client to use hyperquest and a streaming xml parser
      # like xml-stream or xml-object-stream, and then we can make this fully streaming (more performant)
      pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
      pgConnect = Promise.promisify(pgClient.connect, pgClient)
      pgConnect()
      .then () -> new Promise (resolve, reject) ->
        rawDataStream = pgClient.query(copyStream.from("COPY #{rawTableName} (\"#{fields.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8')"))
        rawDataStream.on('finish', resolve)
        rawDataStream.on('error', reject)
        # stream from array to object serializer stream to COPY FROM
        from(results)
        .pipe(utilStreams.objectsToPgText(fields))
        .pipe(rawDataStream)
      .finally () ->
        # always disconnect the db client when we're done
        pgClient.end()
    .catch isNewError, (error) ->
      throw VError(error, "failed to stream raw data to temp table: #{rawTableName}")
  .finally () ->
    # always log out the RETS client when we're done
    retsClient.logout()

    
module.exports =
  tables: tables
  getLastSuccessStartTime: getLastSuccessStartTime
  loadRetsTableUpdates: loadRetsTableUpdates
