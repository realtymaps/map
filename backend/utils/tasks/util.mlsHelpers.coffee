_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require './util.partiallyHandledError'
moment = require('moment')
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require './util.streams'
dbs = require '../config/dbs'
config = require '../config/config'
logger = require '../config/logger'
jobQueue = require './util.jobQueue'
validation = require './util.validation'
require '../config/promisify'
memoize = require 'memoizee'
vm = require 'vm'
tables = require '../config/tables'
validatorBuilder = require '../../common/utils/util.validatorBuilder'
sqlHelpers = require './util.sql.helpers'
retsHelpers = require '../util.retsHelpers'


_streamArrayToDbTable = (objects, tableName, fields) ->
  # stream the results into a COPY FROM query; too bad we currently have to load the whole response into memory
  # first.  Eventually, we can rewrite the rets-promise client to use hyperquest and a streaming xml parser
  # like xml-stream or xml-object-stream, and then we can make this fully streaming (more performant)
  pgClient = new dbs.pg.Client(config.PROPERTY_DB.connection)
  pgConnect = Promise.promisify(pgClient.connect, pgClient)
  pgConnect()
  .then () -> new Promise (resolve, reject) ->
    copyStart = "COPY #{tableName} (\"#{Object.keys(fields).join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8')"
    rawDataStream = pgClient.query(copyStream.from(copyStart))
    rawDataStream.on('finish', resolve)
    rawDataStream.on('error', reject)
    # stream from array to object serializer stream to COPY FROM
    from(objects)
    .pipe utilStreams.objectsToPgText(_.mapValues(fields, 'SystemName'))
    .pipe(rawDataStream)
  .finally () ->
    # always disconnect the db client when we're done
    pgClient.end()
  .then () ->
    return objects.length


_getValues = (list, target) ->
  if !target
    target = {}
  for item in list
    target[item.name] = item.value
  target


# this performs a diff of 2 sets of MLS data, returning only the changed/new/deleted fields as keys, with the value
# taken from row2.  Not all row fields are considered, only those that correspond most directly to the source MLS data,
# excluding those that are expected to be date-related derived values (notably DOM and CDOM)
_diff = (row1, row2, diffExcludeKeys=[]) ->
  fields1 = {}
  fields2 = {}

  # first, flatten the objects
  for groupName, groupList of row1.client_groups
    _getValues(groupList, fields1)
  for groupName, groupList of row1.realtor_groups
    _getValues(groupList, fields1)
  _.extend(fields1, row1.hidden_fields)
  _.extend(fields1, row1.ungrouped_fields)

  for groupName, groupList of row2.client_groups
    _getValues(groupList, fields2)
  for groupName, groupList of row2.realtor_groups
    _getValues(groupList, fields2)
  _.extend(fields2, row2.hidden_fields)
  _.extend(fields2, row2.ungrouped_fields)

  # then get changes from row1 to row2
  result = {}
  for fieldName, value1 of fields1
    if fieldName in diffExcludeKeys
      continue
    if !_.isEqual value1, fields2[fieldName]
      result[fieldName] = if fieldName in fields2 then fields2[fieldName] else null

  # then get fields missing from row1
  _.extend result, _.omit(fields2, Object.keys(fields1))


_getRawTableName = (subtask, suffix) ->
  suffix = if suffix then "_#{suffix}" else ''
  "raw_#{subtask.task_name}#{suffix}_#{subtask.batch_id}"


_createRawTempTable = (tableName, fields) ->
  dbs.properties.knex.schema.createTable tableName, (table) ->
    table.increments('rm_raw_id').notNullable()
    table.boolean('rm_valid')
    table.text('rm_error_msg')
    for fieldName in fields
      table.text(fieldName.replace(/\./g, ''))


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options) ->
  rawTableName = _getRawTableName subtask, options.rawTableSuffix
  tables.config.mls()
  .where(id: subtask.task_name)
  .then (mlsInfo) ->
    mlsInfo = mlsInfo?[0]
    tables.jobQueue.dataLoadHistory()
    .insert
      data_source_id: options.dataSourceId
      data_source_type: 'mls'
      batch_id: subtask.batch_id
      raw_table_name: rawTableName
    .then () ->
      # figure out when we last got updates from this table
      jobQueue.getLastTaskStartTime(subtask.task_name)
    .then (lastSuccess) ->
      now = new Date()
      if now.getTime() - lastSuccess.getTime() > 24*60*60*1000 || now.getDate() != lastSuccess.getDate()
        # if more than a day has elapsed or we've crossed a calendar date boundary, refresh everything and handle deletes
        logger.debug("Last successful run: #{lastSuccess} === performing full refresh")
        lastSuccess = new Date(0)
        doDeletes = true
      else
        logger.debug("Last successful run: #{lastSuccess} --- performing incremental update")
        doDeletes = false
      step3Promise = jobQueue.queueSubsequentSubtask(jobQueue.knex, subtask, "#{subtask.task_name}_recordChangeCounts", {markOtherRowsDeleted: doDeletes}, true)
      step5Promise = jobQueue.queueSubsequentSubtask(jobQueue.knex, subtask, "#{subtask.task_name}_activateNewData", {deleteUntouchedRows: doDeletes}, true)
      Promise.join step3Promise, step5Promise, () ->
        return lastSuccess
    .then (refreshThreshold) ->
      retsHelpers.getDataDump(mlsInfo, null, refreshThreshold)
      .then (results) ->
        if !results?.length
          # nothing to do, GTFO
          return
        # get info about the fields available in the table
        retsHelpers.getColumnList(mlsInfo, mlsInfo.main_property_data.db, mlsInfo.main_property_data.table)
        .then (tableInfo) ->
          fields = _.indexBy(tableInfo.Fields, 'LongName')
          _createRawTempTable(rawTableName, Object.keys(fields))
          .catch isUnhandled, (error) ->
            throw new PartiallyHandledError(error, "failed to create temp table: #{rawTableName}")
          .then () ->
            _streamArrayToDbTable(results, rawTableName, fields)
          .catch isUnhandled, (error) ->
            throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, "failed to load RETS data for update")


_getValidations = (dataSourceId) ->
  tables.config.dataNormalization()
  .where(data_source_id: dataSourceId)
  .orderBy('list')
  .orderBy('ordering')
  .then (validations=[]) ->
    validationMap = {}
    context = vm.createContext(validators: validation.validators)
    for validationDef in validations
      validationMap[validationDef.list] ?= []
      validationDef.transform = vm.runInContext(validationDef.transform, context)
      validationMap[validationDef.list].push(validationDef)
    return validationMap
# memoize it to cache js evals, but only for up to 10 minutes at a time
_getValidations = memoize.promise(_getValidations, maxAge: 600000)

_getUsedKeys = (validationDefinition) ->
  if validationDefinition.input?
    if _.isObject validationDefinition.input
      return _.values(validationDefinition.input)
    else
      return validationDefinition.input
  else
    return [validationDefinition.output]

# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) -> Promise.try () ->
  rawTableName = _getRawTableName subtask, options.rawTableSuffix
  # get rows for this subtask
  rowsPromise = dbs.properties.knex(rawTableName)
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
  # get validations
  validationPromise = _getValidations(options.dataSourceId)
  # get start time for "last updated" stamp
  startTimePromise = jobQueue.getLastTaskStartTime(subtask.task_name, false)
  Promise.join rowsPromise, validationPromise, startTimePromise, (rows, validationMap, startTime) ->
    # calculate the keys that are grouped for later
    usedKeys = ['rm_raw_id', 'rm_valid', 'rm_error_msg'] # exclude these internal-only fields from showing up as "unused"
    diffExcludeKeys = []
    for groupName, validationList of validationMap
      for validationDefinition in validationList
        # generally, don't count the 'base' fields as being used, but we do for 'address' and 'status', as the source
        # fields for those don't have to be explicitly reused
        if validationDefinition.list != 'base' || validationDefinition.output == 'address' || validationDefinition.output == 'status_display'
          usedKeys = usedKeys.concat(_getUsedKeys(validationDefinition))
        else if validationDefinition.output == 'days_on_market'
          # explicitly exclude these keys from diff, because they are derived values based on date
          diffExcludeKeys = _getUsedKeys(validationDefinition)
    promises = for row in rows
      do (row) ->
        stats =
          data_source_id: options.dataSourceId
          batch_id: subtask.batch_id
          rm_raw_id: row.rm_raw_id
          up_to_date: startTime
        Promise.props(_.mapValues(validationMap, validation.validateAndTransform.bind(null, row)))
        .then _updateRecord.bind(null, stats, diffExcludeKeys, usedKeys, row)
        .then () ->
          dbs.properties.knex(rawTableName)
          .where(rm_raw_id: row.rm_raw_id)
          .update(rm_valid: true)
        .catch validation.DataValidationError, (err) ->
          dbs.properties.knex(rawTableName)
          .where(rm_raw_id: row.rm_raw_id)
          .update(rm_valid: false, rm_error_msg: err.toString())
    Promise.all promises


_updateRecord = (stats, diffExcludeKeys, usedKeys, rawData, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = _getValues(normalizedData.base || [])
  normalizedData.general.unshift(name: 'Address', value: base.address)
  normalizedData.general.unshift(name: 'Status', value: base.status_display)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(tables.propertyData.mls(), base.address)
    hide_listing: base.hide_listing ? false
    client_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      listing: normalizedData.listing || []
      building: normalizedData.building || []
      dimensions: normalizedData.dimensions || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    realtor_groups:
      contacts: normalizedData.contacts || []
      realtor: normalizedData.realtor || []
      sale: normalizedData.sale || []
    hidden_fields: _getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
  updateRow = _.extend base, stats, data
  # check for an existing row
  tables.propertyData.mls()
  .select('*')
  .where
    mls_uuid: updateRow.mls_uuid
    data_source_id: updateRow.data_source_id
  .then (result) ->
    if !result?.length
      # no existing row, just insert
      tables.propertyData.mls()
      .insert(updateRow)
    else
      # found an existing row, so need to update, but include change log
      result = result[0]
      updateRow.change_history = result.change_history ? []
      changes = _diff(updateRow, result, diffExcludeKeys)
      if !_.isEmpty changes
        updateRow.change_history.push changes
      updateRow.change_history = sqlHelpers.safeJsonArray(tables.propertyData.mls(), updateRow.change_history)
      tables.propertyData.mls()
      .where
        mls_uuid: updateRow.mls_uuid
        data_source_id: updateRow.data_source_id
      .update(updateRow)


recordChangeCounts = (subtask) ->
  Promise.try () ->
    if subtask.data.markOtherRowsDeleted
      # mark any rows not updated by this task (and not already marked) as deleted -- we only do this when doing a full
      # refresh of all data, because this would be overzealous if we're just doing an incremental update; the update
      # will resolve to a count of affected rows
      tables.propertyData.mls()
      .whereNot(batch_id: subtask.batch_id)
      .whereNull('deleted')
      .update(deleted: subtask.batch_id)
  .then (deletedCount=0) ->
    # get a count of rows from this batch with null change history, i.e. newly-inserted rows
    insertedSubquery = () ->
      tables.propertyData.mls(this)
      .where(batch_id: subtask.batch_id)
      .whereNull('change_history')
      .count('*')
    # get a count of rows from this batch without a null change history, i.e. newly-updated rows
    updatedSubquery = () ->
      tables.propertyData.mls(this)
      .where(batch_id: subtask.batch_id)
      .whereNotNull('change_history')
      .count('*')
    tables.jobQueue.dataLoadHistory()
    .where(batch_id: subtask.batch_id)
    .update
      inserted_rows: insertedSubquery
      updated_rows: updatedSubquery
      deleted_rows: deletedCount


finalizeData = (subtask, id) ->
  listingsPromise = tables.propertyData.mls()
  .select('*')
  .where(id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .orderByRaw('close_date DESC NULLS FIRST')
  parcelsPromise = tables.propertyData.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(id)
  # TODO: we also need to select from the tax table for owner name info
  Promise.join listingsPromise, parcelsPromise, (listings=[], parcel=[]) ->
    if listings.length == 0
      # might happen if a listing is deleted during the day -- we'll catch it during the next full sync
      return
    listing = listings.shift()
    listing.data_source_type = 'mls'
    listing.active = false
    _.extend(listing, parcel[0])
    delete listing.deleted
    delete listing.hide_address
    delete listing.hide_listing
    delete listing.rm_inserted_time
    delete listing.rm_modified_time
    listing.prior_listings = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listings)
    listing.address = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.address)
    listing.change_history = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.change_history)
    # JWI: I don't think the below should be necessary, but there was a while where they seemed to be.  I've since made
    # some other changes though, so I'm leaving them commented out in hopes it will work without.  If there are problems
    # with JSON syntax, they might need to be uncommented.
    #listing.hidden_fields = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.hidden_fields)
    #listing.ungrouped_fields = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.ungrouped_fields)
    #listing.realtor_groups = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.realtor_groups)
    #listing.client_groups = sqlHelpers.safeJsonArray(tables.propertyData.combined(), listing.client_groups)
    tables.propertyData.combined()
    .insert(listing)


activateNewData = (subtask) ->
  # this function flips inactive rows to active, active rows to inactive, and deletes the now-inactive rows
  if subtask.data.deleteUntouchedRows
    # in this mode, we perform those actions to all rows on this data_source_id, because we assume this is a
    # full data sync, and if we didn't touch it that means it should be deleted
    tables.propertyData.combined()
    .where(data_source_id: subtask.data_source_id)
    .update(active: dbs.properties.knex.raw('NOT "active"'))
    .then () ->
      tables.propertyData.combined()
      .where
        data_source_id: subtask.data_source_id
        active: false
      .delete()
  else
    # in this mode, we're doing an incremental update, so we only want to perform those actions for rows with an
    # the rm_property_id that has been updated in this batch
    checkSubquery = () ->
      tables.propertyData.combined(this)
      .select('rm_property_id')
      .where
          data_source_id: subtask.task_name
          batch_id: subtask.batch_id
          active: false
    tables.propertyData.combined()
    .where
      data_source_id: subtask.task_name
      batch_id: subtask.batch_id
    .whereIn 'rm_property_id', checkSubquery
    .update(active: dbs.properties.knex.raw('NOT "active"'))
    .then () ->
      tables.propertyData.combined()
      .where
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id
        active: false
      .delete()

module.exports =
  loadRetsTableUpdates: loadRetsTableUpdates
  normalizeData: normalizeData
  recordChangeCounts: recordChangeCounts
  finalizeData: finalizeData
  activateNewData: activateNewData
