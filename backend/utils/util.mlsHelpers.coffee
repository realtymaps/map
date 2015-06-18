_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require './util.partiallyHandledError'
rets = require 'rets-client'
Encryptor = require './util.encryptor'
moment = require('moment')
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require './util.streams'
dbs = require '../config/dbs'
config = require '../config/config'
taskHelpers = require './tasks/util.taskHelpers'
logger = require '../config/logger'
jobQueue = require './util.jobQueue'
validation = require './util.validation'
require '../config/promisify'
memoize = require 'memoizee'
vm = require 'vm'
sqlHelpers = require './../utils/util.sql.helpers'

# we should probably clean up these old Bookshelf models somehow so we have a better way of getting their table names
Parcel = require "../models/model.parcels"


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


_getValues = (obj, list) ->
  for item in list
    obj[item.name] = item.value

# this performs a diff of 2 sets of MLS data, returning only the changed/new/deleted fields as keys, with the value
# taken from row2.  Not all row fields are considered, only those that correspond most directly to the source MLS data,
# excluding those that are expected to be date-related derived values (notably DOM and CDOM)
_diff = (row1, row2, diffExcludeKeys=[]) ->
  result = {}
  fields1 = {}
  fields2 = {}

  # first, flatten the objects
  for groupName, groupList of row1.client_groups
    _getValues fields1, groupList
    _getValues fields2, row2.client_groups[groupName]
  for groupName, groupList of row1.realtor_groups
    _getValues fields1, groupList
    _getValues fields2, row2.realtor_groups[groupName]
  _getValues fields1, row2.realtor_groups.hidden_fields
  _getValues fields2, row2.realtor_groups.hidden_fields
  _getValues fields1, row2.realtor_groups.ungrouped_fields
  _getValues fields2, row2.realtor_groups.ungrouped_fields

  # then get changes from row1 to row2
  for fieldName, value1 of fields1
    if fieldName in diffExcludeKeys
      continue
    if !_.isEqual value1, fields2[fieldName]
      result[fieldName] = if fieldName in fields2 then fields2[fieldName] else null

  # then get fields missing from row1
  _.extend result, _.omit(fields2, Object.keys(fields1))


# loads all records from a given RETS table that have changed since the last successful run of the task
loadRetsTableUpdates = (subtask, options) ->
  rawTableName = taskHelpers.getRawTableName subtask, options.rawTableSuffix
  retsClient = new rets.Client
    loginUrl: subtask.task_data.url
    username: subtask.task_data.login
    password: encryptor.decrypt(subtask.task_data.password)
  retsClient.login()
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(new Error("#{error.replyCode}"), "RETS login failed")
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
        lastSuccess = new Date(0)
        doDeletes = true
      else
        doDeletes = false
      step3Promise = jobQueue.queueSubsequentSubtask(jobQueue.knex, subtask, 'recordChangeCounts', {markOtherRowsDeleted: doDeletes}, true)
      step5Promise = jobQueue.queueSubsequentSubtask(jobQueue.knex, subtask, 'activateNewData', {deleteUntouchedRows: doDeletes}, true)
      Promise.join(step3Promise, step5Promise)
      .then () ->
        return lastSuccess
    .then (refreshThreshold) ->
      _getData(retsClient, options.retsDbName, options.retsTableName, moment.utc(refreshThreshold).format(options.retsQueryTemplate))
    .then (results) ->
      _streamArrayToDbTable(results, rawTableName, fields)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
    .finally () ->
      # always log out the RETS client when we're done
      retsClient.logout()

_getData = (client, database, table, momentThreshold) ->
  logger.info "#### mlsHelper: _getData"
  # if !momentThreshold?
  #   momentThreshold = moment.utc(new Day(0)).format(options.retsQueryTemplate)

  # query for any data newer than momentThreshold
  console.log "#### _getData database:"
  console.log database
  console.log "#### _getData table:"
  console.log table


  client.search.query(database, table, momentThreshold)

  .catch isUnhandled, (error) ->
    console.log '#### _getData error:'
    console.log error
    if error.replyCode == "20201"
      # code for 0 results, not really an error (DMQL is a clunky language)
      return []
    # TODO: else if error.replyCode == "20208"
    # code for too many results, must manually paginate or something to get all the data
    throw new PartiallyHandledError(error, "failed to query RETS system")

getDataDump = (mlsInfo) ->
  logger.info "#### mlsHelper: getDataDump"
  _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password
  .then (retsClient) ->
    momentThreshold = moment.utc(new Date(0)).format(mlsInfo.main_property_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.main_property_data.field))
    _getData(retsClient, mlsInfo.main_property_data.db, mlsInfo.main_property_data.table, momentThreshold, limit: 1000)
    # list = [
    #   { "test": "0.00", "test2": "None", "test3": "str1" },
    #   { "test": "3.00", "test2": "2", "test3": "" }
    # ]
    # list

_getRetsClient = (loginUrl, username, password) ->
  Promise.try () ->
    new rets.Client
      loginUrl: loginUrl
      username: username
      password: encryptor.decrypt(password)
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "RETS client could not be created")
  .then (retsClient) ->
    retsClient.login()
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, "RETS login failed")

getDatabaseList = (serverInfo) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password
  .then (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      logger.error error.stack
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, "Failed to retrieve RETS databases")
    .then (response) ->
      _.map response.Resources, (r) ->
        _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']
    .finally () ->
      retsClient.logout()

getTableList = (serverInfo, databaseName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password
  .then (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, "Failed to retrieve RETS tables")
    .then (response) ->
      _.map response.Classes, (r) ->
        _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']
    .finally () ->
      retsClient.logout()

getColumnList = (serverInfo, databaseName, tableName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password
  .then (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(new Error("#{error.replyText} (#{error.replyCode})"), "Failed to retrieve RETS columns")
    .then (response) ->
      _.map response.Fields, (r) ->
        _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType']
    .finally () ->
      retsClient.logout()


_getValidations = (dataSourceId) ->
  jobQueue.knex(taskHelpers.tables.dataNormalizationConfig)
  .where(data_source_id: dataSourceId)
  .orderBy('output_group')
  .orderBy('display_order')
  .then (validations=[]) ->
    validationMap = {}
    context = vm.createContext(validators: validation.validators)
    for validation in validations
      validationMap[validation.output_group] ?= []
      validation.transform = vm.runInContext(validation.transform, context)
      validationMap[validation.output_group].push(validation)
    validationMap
# memoize it to cache js evals, but only for up to 10 minutes at a time
_getValidations = Promise.promisify memoize(Promise.nodeifyWrapper(_getValidations), maxAge: 600000)

# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) -> Promise.try () ->
  rawTableName = taskHelpers.getRawTableName subtask, options.rawTableSuffix
  # get rows for this subtask
  rowsPromise = dbs.properties.knex(rawTableName)
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
  # get validations
  validationPromise = _getValidations(options.dataSourceId)
  # get start time for "last updated" stamp
  startTimePromise = taskHelpers.getLastStartTime(subtask.task_name, false)
  Promise.join(rowsPromise, validationPromise, startTimePromise)
  .then (rows, validationMap, startTime) ->
    # calculate the keys that are grouped for later
    usedKeys = []
    for groupName, validationList of validationMap
      for validationDefinition in validationList
        if validationDefinition.input?
          if _.isObject validationDefinition.input
            newKeys = Object.keys(validationDefinition.input)
          else
            newKeys = validationDefinition.input
        else
          newKeys = [validationDefinition.output]
        usedKeys.concat(newKeys)
        if validationDefinition.list == 'base' && validationDefinition.output = 'days_on_market'
          diffExcludeKeys = newKeys
    Promise.map rows, (row) ->
      Promise.props(_.mapValues(validationMap, validation.validateAndTransform.bind(null, row)))
      .then _updateRecord.bind(null, diffExcludeKeys, usedKeys)
      .then () ->
        dbs.properties.knex(rawTableName)
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: true)
      .catch validation.DataValidationError, (err) ->
        dbs.properties.knex(rawTableName)
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: false, rm_error_msg: err.toString())


_updateRecord = (diffExcludeKeys, usedKeys, normalizedData) -> Promise.try () ->
  # build the row's new values
  _.extend normalizedData.base,
    data_source_id: options.dataSourceId
    batch_id: subtask.batch_id
    up_to_date: startTime
    client_groups:
      general: normalizedData.general
      details: normalizedData.details
      listing: normalizedData.listing
      building: normalizedData.building
      dimensions: normalizedData.dimensions
      lot: normalizedData.lot
      location: normalizedData.location
      restrictions: normalizedData.restrictions
    realtor_groups:
      contacts: normalizedData.contacts
      realtor: normalizedData.realtor
      sale: normalizedData.sale
    hidden_fields: normalizedData.hidden
    ungrouped_fields: _.omit(row, usedKeys)
  .then (updateRow) ->
    # check for an existing row
    dbs.properties.knex(taskHelpers.tables.mlsData)
    .select('*')
    .where
      mls_uuid: updateRow.mls_uuid
      data_source_id: updateRow.data_source_id
    .then (result) ->
      if !result?.length
        # no existing row, just insert
        dbs.properties.knex(taskHelpers.tables.mlsData)
        .insert(updateRow)
      else
        # found an existing row, so need to update, but include change log
        updateRow.change_history = result.change_history ? []
        changes = _diff(updateRow, result, diffExcludeKeys)
        if !_.isEmpty changes
          updateRow.change_history.push changes
        dbs.properties.knex(taskHelpers.tables.mlsData)
        .where
          mls_uuid: updateRow.mls_uuid
          data_source_id: updateRow.data_source_id
        .update(updateRow)


recordChangeCounts = (subtask) ->
  Promise.try () ->
    if subtask.data.markOtherRowsDeleted
      # mark any rows not updated by this task (and not already marked) as deleted -- we only do this when doing a full
      # refresh of all data, because this would be overzealous if we're just doing an incremental update; this subquery
      # will resolve to a count of affected rows
      return dbs.properties.knex(taskHelpers.tables.mlsData)
      .whereNot(batch_id: subtask.batch_id)
      .whereNotNull('deleted')
      .update(deleted: subtask.batch_id)
    else
      # return 0 because we use this as the count of deleted rows
      return 0
  .then (deletedCount) ->
    # get a count of rows from this batch with null change history, i.e. newly-inserted rows
    insertedSubquery = dbs.properties.knex(taskHelpers.tables.mlsData)
    .where
      batch_id: subtask.batch_id
      change_history: null
    .count('*')
    # get a count of rows from this batch without a null change history, i.e. newly-updated rows
    updatedSubquery = dbs.properties.knex(taskHelpers.tables.mlsData)
    .where(batch_id: subtask.batch_id)
    .whereNotNull('change_history')
    .count('*')
    dbs.properties.knex(taskHelpers.tables.dataLoadHistory)
    .where(batch_id: subtask.batch_id)
    .update
      inserted_rows: insertedSubquery
      updated_rows: updatedSubquery
      deleted_rows: deletedCount


finalizeData = (subtask, id) ->
  listingsPromise = dbs.properties.knex(taskHelpers.tables.mlsData)
  .select('*')
  .where(rm_property_id: id)
  .orderByRaw('close_date NULLS FIRST DESC')
  parcelPromise = dbs.properties.knex(sqlHelpers.tableName(Parcel))
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(rm_property_id: id)
  # we also need to select from the tax table for owner name info 
  Promise.join(listingsPromise, parcelsPromise)
  .then (listings, parcel=[]) ->
    listing = listings.shift()
    listing.prior_listings = listings
    listing.data_source_type = 'mls'
    listing.active = false
    delete listing.deleted
    _.extend(listing, parcel)
    dbs.properties.knex('combined_data')
    .insert(listing)


activateNewData = (subtask) ->
  # this function flips inactive rows to active, active rows to inactive, and deletes the now-inactive rows
  if subtask.data.deleteUntouchedRows
    # in this mode, we perform those actions to all rows on this data_source_id, because we assume this is a
    # full data sync, and if we didn't touch it that means it should be deleted
    dbs.properties.knex('combined_data')
    .where(data_source_id: subtask.data_source_id)
    .update(active: dbs.properties.knex.raw('NOT "active"'))
    .then () ->
      dbs.properties.knex('combined_data')
      .where
        data_source_id: subtask.data_source_id
        active: false
      .delete()
  else
    # in this mode, we're doing an incremental update, so we only want to perform those actions for rows with an
    # the rm_property_id that has been updated in this batch
    dbs.properties.knex('combined_data')
    .where
      data_source_id: subtask.data_source_id
      batch_id: subtask.batch_id
    .whereExists () ->
      this.select()
      .from('check')
      .where
        "check.data_source_id": subtask.data_source_id
        "check.batch_id": subtask.batch_id
        "check.active": false
        "check.rm_property_id": dbs.properties.knex.raw('combined_data.rm_property_id')
      .as('check')
    .update(active: dbs.properties.knex.raw('NOT "active"'))
    .then () ->
      dbs.properties.knex('combined_data')
      .where
        data_source_id: subtask.data_source_id
        batch_id: subtask.batch_id
        active: false
      .delete()




module.exports =
  loadRetsTableUpdates: loadRetsTableUpdates
  normalizeData: normalizeData
  getDatabaseList: getDatabaseList
  getTableList: getTableList
  getColumnList: getColumnList
  recordChangeCounts: recordChangeCounts
  finalizeData: finalizeData
  activateNewData: activateNewData
  getDataDump: getDataDump