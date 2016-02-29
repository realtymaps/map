tables = require '../../config/tables'
Promise = require 'bluebird'
jobQueue = require '../util.jobQueue'
validation = require '../util.validation'
validatorBuilder = require '../../../common/utils/util.validatorBuilder'
memoize = require 'memoizee'
vm = require 'vm'
_ = require 'lodash'
logger = require('../../config/logger').spawn('task')
sqlHelpers = require '../util.sql.helpers'
dbs = require '../../config/dbs'
{HardFail, SoftFail} = require '../errors/util.error.jobQueue'
copyStream = require 'pg-copy-streams'
utilStreams = require '../util.streams'
through2 = require 'through2'


DELETE =
  UNTOUCHED: 'untouched'
  INDICATED: 'indicated'
  NONE: 'none'


buildUniqueSubtaskName = (subtask, prefix) ->
  parts = [subtask.batch_id, subtask.task_name, subtask.data.dataType]
  if subtask.data.rawTableSuffix
    parts.push(subtask.data.rawTableSuffix)
  if prefix
    parts.unshift(prefix)
  parts.join('_')


_countInvalidRows = (subid, assignedFalse) ->
  query = tables.temp(subid: subid)
  .count('* AS count')
  if assignedFalse
    query.where(rm_valid: false)
  else
    query.whereNull('rm_valid')
  query
  .then (results) ->
    results?[0].count ? 0


recordChangeCounts = (subtask) ->
  subid = buildUniqueSubtaskName(subtask)
  subset =
    data_source_id: subtask.task_name
  _.extend(subset, subtask.data.subset)
  deletedPromise = Promise.try () ->
    if subtask.data.deletes == DELETE.UNTOUCHED
      # check if any rows will be left active after delete, and error if not; for efficiency, just grab the id of the
      # first such row rather than return all or count them all
      tables.property[subtask.data.dataType](subid: subtask.data.normalSubid)
      .select('rm_raw_id')
      .where(batch_id: subtask.batch_id)
      .where(subset)
      .whereNull('deleted')
      .limit(1)
      .then (row) ->
        if !row?[0]?
          throw new HardFail("operation would delete all active rows for #{subtask.task_name}")
      .then () ->
        # mark any rows not updated by this task (and not already marked) as deleted -- we only do this when doing a full
        # refresh of all data, because this would be overzealous if we're just doing an incremental update; the update
        # will resolve to a count of affected rows
        tables.property[subtask.data.dataType](subid: subtask.data.normalSubid)
        .whereNot(batch_id: subtask.batch_id)
        .where(subset)
        .whereNull('deleted')
        .update(deleted: subtask.batch_id)
    else if subtask.data.deletes == DELETE.INDICATED
      tables.property[subtask.data.dataType](subid: subtask.data.normalSubid)
      .count('*')
      .where(subset)
      .where(deleted: subtask.batch_id)
      .then (results) ->
        results[0].count
  # get a count of raw rows from all raw tables from this batch with rm_valid == false
  invalidPromise = _countInvalidRows(subid, true)
  # get a count of raw rows from all raw tables from this batch with rm_valid == NULL
  unvalidatedPromise = _countInvalidRows(subid, false)
  # get a count of rows from this batch with null change history, i.e. newly-inserted rows
  insertedPromise = tables.property[subtask.data.dataType](subid: subtask.data.normalSubid)
  .where(inserted: subtask.batch_id)
  .where(subset)
  .count('*')
  .then (results) ->
    results[0].count
  # get a count of rows from this batch without a null change history, i.e. newly-updated rows
  updatedPromise = tables.property[subtask.data.dataType](subid: subtask.data.normalSubid)
  .where(updated: subtask.batch_id)
  .where(subset)
  .count('*')
  .then (results) ->
    results[0].count
  touchedPromise = tables.property[subtask.data.dataType](subid: subtask.data.normalSubid)
  .where(batch_id: subtask.batch_id)
  .where(subset)
  .orWhere(deleted: subtask.batch_id)
  .where(subset)
  .count('*')
  .then (results) ->
    results[0].count
  updateDataLoadHistory = (deletedCount=0, invalidCount, unvalidatedCount, insertedCount, updatedCount, touchedCount) ->
    tables.jobQueue.dataLoadHistory()
    .where(raw_table_name: tables.temp.buildTableName(subid))
    .update
      invalid_rows: invalidCount
      unvalidated_rows: unvalidatedCount
      inserted_rows: insertedCount
      updated_rows: updatedCount
      deleted_rows: deletedCount
      touched_rows: touchedCount
  Promise.join(deletedPromise, invalidPromise, unvalidatedPromise, insertedPromise, updatedPromise, touchedPromise, updateDataLoadHistory)


# this function flips inactive rows to active, active rows to inactive, and deletes now-inactive and extraneous rows
activateNewData = (subtask) ->
  # wrapping this in a transaction improves performance, since we're editing some rows twice
  dbs.get('main').transaction (transaction) ->
    if subtask.data.deletes == DELETE.UNTOUCHED
      # in this mode, we perform those actions to all rows on this data_source_id, because we assume this is a
      # full data sync, and if we didn't touch it that means it should be deleted
      activatePromise = tables.property.combined(transaction: transaction)
      .where(data_source_id: subtask.task_name)
      .update(active: dbs.get('main').raw('NOT "active"'))
    else
      # in this mode, we're doing an incremental update, so we only want to perform those actions for rows with an
      # rm_property_id that has been updated in this batch
      activatePromise = tables.property.combined(transaction: transaction, as: 'updater')
      .whereExists () ->
        tables.property.combined(transaction: this)
        .select(1)
        .where
          update_source: subtask.task_name
          batch_id: subtask.batch_id
          active: false
          rm_property_id: dbs.get('main').raw("updater.rm_property_id")
          data_source_id: dbs.get('main').raw("updater.data_source_id")
      .update(active: dbs.get('main').raw('NOT "active"'))

    activatePromise
    .then () ->
      # delete inactive rows
      tables.property.combined(transaction: transaction)
      .where
        data_source_id: subtask.task_name
        active: false
      .delete()
    .then () ->
      # delete rows marked explicitly for deletion
      tables.property.combined(transaction: transaction, as: 'deleter')
      .where(data_source_id: subtask.task_name)
      .whereExists () ->
        tables.property.deletes(transaction: this)
        .select(1)
        .where
          data_source_id: subtask.task_name
          batch_id: subtask.batch_id
          rm_property_id: dbs.get('main').raw("deleter.rm_property_id")
      .delete()


_getUsedInputFields = (validationDefinition) ->
  if validationDefinition.input?
    if _.isObject validationDefinition.input
      return _.values(validationDefinition.input)
    else
      return validationDefinition.input
  else
    return [validationDefinition.output]


getValidationInfo = (dataSourceType, dataSourceId, dataType, listName, fieldName) ->
  if dataSourceType == 'mls'
    dataSourcePromise = Promise.try () ->
      tables.config.mls()
      .where
        id: dataSourceId
      .then (mlsConfig) ->
        mlsConfig.data_rules
  else if dataSourceType == 'county'
    dataSourcePromise = Promise.try () ->
      Promise.resolve {} # no global rules, so far

  dataSourcePromise
  .then (global_rules) ->
    whereClause =
      data_source_id: dataSourceId
      data_type: dataType
    if listName
      whereClause.list = listName
    if fieldName
      whereClause.output = fieldName
    tables.config.dataNormalization()
    .where(whereClause)
    .orderBy('list')
    .orderBy('ordering')
    .then (validations=[]) ->
      validationMap = {}
      for validationDef in validations
        validationMap[validationDef.list] ?= []

        # If transform was overridden, use it directly
        if !_.isEmpty validationDef.transform
          if !context
            context = vm.createContext(validators: validation.validators)
          validationDef.transform = vm.runInContext(validationDef.transform, context)

        # Most common case, generate the transform from the rule configuration
        else
          if validationDef.list == 'base'
            rule = validatorBuilder.buildBaseRule(dataSourceType, dataType) validationDef
          else
            rule = validatorBuilder.buildDataRule validationDef

          transforms = rule.getTransform global_rules
          if !_.isArray transforms
            transforms = [ transforms ]

          validationDef.transform = _.map transforms, (transform) ->
            validation.validators[transform.name](transform.options)

        validationMap[validationDef.list].push(validationDef)
      # pre-calculate the keys that are grouped for later use
      usedKeys = ['rm_raw_id', 'rm_valid', 'rm_error_msg'] # exclude these internal-only fields from showing up as "unused"
      diffExcludeKeys = []
      if dataSourceType == 'mls'
        for groupName, validationList of validationMap
          for validationDefinition in validationList
            # generally, don't count the 'base' fields as being used, but we do for 'address' and 'status', as the source
            # fields for those don't have to be explicitly reused
            if validationDefinition.list != 'base' || validationDefinition.output in ['address', 'status_display']
              usedKeys = usedKeys.concat(_getUsedInputFields(validationDefinition))
            else if validationDefinition.output == 'days_on_market'
              # explicitly exclude these keys from diff, because they are derived values based on date
              diffExcludeKeys = _getUsedInputFields(validationDefinition)
      else if dataSourceType == 'county'
        for groupName, validationList of validationMap
          for validationDefinition in validationList
            # generally, don't count the 'base' fields as being used, but we do for 'address', as the source
            # fields for those don't have to be explicitly reused
            if validationDefinition.list != 'base' || validationDefinition.output in ['address', 'owner_address', 'owner_name', 'owner_name_2']
              usedKeys = usedKeys.concat(_getUsedInputFields(validationDefinition))
      return {validationMap: validationMap, usedKeys: usedKeys, diffExcludeKeys: diffExcludeKeys}
# memoize it to cache js evals, but only for up to ~24 hours at a time
getValidationInfo = memoize.promise(getValidationInfo, primitive: true, maxAge: 24*60*60*1000)


# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) -> Promise.try () ->
  successes = []
  rawSubid = buildUniqueSubtaskName(subtask)
  # get rows for this subtask
  rowsPromise = tables.temp(subid: rawSubid)
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
  # get validations
  validationPromise = getValidationInfo(options.dataSourceType, options.dataSourceId, subtask.data.dataType)
  # get start time for "last updated" stamp
  startTimePromise = jobQueue.getLastTaskStartTime(subtask.task_name, false)
  doNormalization = (rows, validationInfo, startTime) ->
    processRow = (row, index, length) ->
      stats =
        data_source_id: options.dataSourceId
        batch_id: subtask.batch_id
        rm_raw_id: row.rm_raw_id
        up_to_date: startTime
      Promise.props(_.mapValues(validationInfo.validationMap, validation.validateAndTransform.bind(null, row)))
      .cancellable()
      .then options.buildRecord.bind(null, stats, validationInfo.usedKeys, row, subtask.data.dataType)
      .then _updateRecord.bind(null, stats, validationInfo.diffExcludeKeys, subtask.data.dataType, subtask.data.normalSubid)
      .then (rm_property_id) ->
        successes.push(rm_property_id)
      #.then () ->
      #  tables.temp(subid: rawSubid)
      #  .where(rm_raw_id: row.rm_raw_id)
      #  .update(rm_valid: true)
      .catch validation.DataValidationError, (err) ->
        tables.temp(subid: rawSubid)
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: false, rm_error_msg: err.toString())
    Promise.each(rows, processRow)
  Promise.join(rowsPromise, validationPromise, startTimePromise, doNormalization)
  .then () ->
    successes

_updateRecord = (stats, diffExcludeKeys, dataType, subid, updateRow) -> Promise.try () ->
  # check for an existing row
  tables.property[dataType](subid: subid)
  .select('*')
  .where
    data_source_uuid: updateRow.data_source_uuid
    data_source_id: updateRow.data_source_id
  .then (result) ->
    if !result?.length
      # no existing row, just insert
      updateRow.inserted = stats.batch_id
      tables.property[dataType](subid: subid)
      .insert(updateRow)
    else
      # found an existing row, so need to update, but include change log
      result = result[0]
      updateRow.change_history = result.change_history ? []
      changes = _getRowChanges(updateRow, result, diffExcludeKeys)
      if changes.deleted == stats.batch_id
        # it wasn't really deleted, just purged earlier in this task as per black knight data flow
        delete changes.deleted
      if !_.isEmpty changes
        updateRow.change_history.push changes
        updateRow.updated = stats.batch_id
      updateRow.change_history = sqlHelpers.safeJsonArray(updateRow.change_history)
      tables.property[dataType](subid: subid)
      .where
        data_source_uuid: updateRow.data_source_uuid
        data_source_id: updateRow.data_source_id
      .update(updateRow)
  .then () ->
    updateRow.rm_property_id


getValues = (list, target) ->
  if !target
    target = {}
  for item in list
    target[item.name] = item.value
  target


# this performs a diff of 2 sets of data, returning only the changed/new/deleted fields as keys, with the value
# taken from row2.  Not all row fields are considered, only those that correspond most directly to the source data,
# excluding those that are expected to be date-related derived values (such as DOM and CDOM for MLS listings)
_getRowChanges = (row1, row2, diffExcludeKeys=[]) ->
  fields1 = {}
  fields2 = {}

  # first, flatten the objects
  for groupName, groupList of row1.shared_groups
    getValues(groupList, fields1)
  for groupName, groupList of row1.subscriber_groups
    getValues(groupList, fields1)
  _.extend(fields1, row1.hidden_fields)
  _.extend(fields1, row1.ungrouped_fields)

  for groupName, groupList of row2.shared_groups
    getValues(groupList, fields2)
  for groupName, groupList of row2.subscriber_groups
    getValues(groupList, fields2)
  _.extend(fields2, row2.hidden_fields)
  _.extend(fields2, row2.ungrouped_fields)

  # then get changes from row1 to row2
  result = {}
  for fieldName, value1 of fields1
    if fieldName in diffExcludeKeys
      continue
    if !_.isEqual value1, fields2[fieldName]
      result[fieldName] = (fields2[fieldName] ? null)

  # then get fields missing from row1
  _.extend result, _.omit(fields2, Object.keys(fields1))


finalizeEntry = (entries) ->
  entry = entries.shift()
  entry.active = false
  delete entry.deleted
  delete entry.hide_address
  delete entry.hide_listing
  delete entry.rm_inserted_time
  delete entry.rm_modified_time
  entry.prior_entries = sqlHelpers.safeJsonArray(entries)
  entry.address = sqlHelpers.safeJsonArray(entry.address)
  entry.owner_address = sqlHelpers.safeJsonArray(entry.owner_address)
  entry.change_history = sqlHelpers.safeJsonArray(entry.change_history)
  entry.update_source = entry.data_source_id
  entry


manageRawDataStream = (tableName, dataLoadHistory, objectStream) ->
  dbs.getPlainClient 'raw_temp', (promiseQuery, streamQuery) ->
    tables.jobQueue.dataLoadHistory()
    .insert(dataLoadHistory)
    .then () ->
      promiseQuery('BEGIN TRANSACTION')
    .then () -> new Promise (resolve, reject) ->
      # stream the results into a COPY FROM query
      delimiter = null
      dbStream = null
      donePayload = null
      dbStreamer = null
      hadError = false
      onError = (err) ->
        reject(err)
        dbStreamer.unpipe(dbStream)
        dbStream.write('\\.\n')
        dbStream.end()
        hadError = true
      dbStreamTransform = (event, encoding, callback) ->
        try
          switch event.type
            when 'data'
              this.push(utilStreams.pgStreamEscape(event.payload))
              this.push('\n')
              callback()
            when 'delimiter'
              delimiter = event.payload
              callback()
            when 'columns'
              columns = []
              for fieldName in event.payload
                columns.push fieldName.replace(/\./g, '')
              promiseQuery(dbs.get('raw_temp').schema.dropTableIfExists(tableName))
              .then () ->
                tables.jobQueue.dataLoadHistory()
                .where(raw_table_name: tableName)
                .delete()
              .then () ->
                createRawTable = dbs.get('raw_temp').schema.createTable tableName, (table) ->
                  table.increments('rm_raw_id').notNullable()
                  table.boolean('rm_valid')
                  table.text('rm_error_msg')
                  for fieldName in columns
                    table.text(fieldName)
                promiseQuery(createRawTable.toString().replace('"rm_raw_id" serial primary key,', '"rm_raw_id" serial,'))
              .then () ->
                copyStart = "COPY \"#{tableName}\" (\"#{columns.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8', NULL '', DELIMITER '#{delimiter}')"
                dbStream = streamQuery(copyStream.from(copyStart))
                dbStreamer.pipe(dbStream)
                callback()
            when 'done'
              donePayload = event.payload
              callback()
            when 'error'
              onError(event.payload)
              callback()
            else
              callback()
        catch err
          onError(err)
          callback()
      dbStreamer = through2.obj dbStreamTransform, (callback) ->
        this.push('\\.\n')
        callback()
        if !hadError
          resolve(donePayload)
      objectStream.pipe(dbStreamer)
    .catch (err) ->
      logger.error("problem streaming to #{tableName}: #{err}")
      promiseQuery('ROLLBACK TRANSACTION')
      .then () ->
        tables.jobQueue.dataLoadHistory()
        .where(raw_table_name: tableName)
        .delete()
      .catch (err2) ->
        throw err
      .then () ->
        throw err
    .then (count) ->
      promiseQuery("CREATE INDEX ON \"#{tableName}\" (rm_raw_id)")
      promiseQuery('COMMIT TRANSACTION')
      .then () ->
        tables.jobQueue.dataLoadHistory()
        .where(raw_table_name: tableName)
        .update(raw_rows: count)
      .then () ->
        count


ensureNormalizedTable = (dataType, subid) ->
  tableName = tables.property[dataType].buildTableName(subid)
  dbs.get('normalized')
  .select(1)
  .from('pg_catalog.pg_class')
  .where
    relname: tableName
    relkind: 'r'
  .then (check=[]) ->
    if check.length > 0
      return
    dbs.get('normalized').schema.createTable tableName, (table) ->
      table.timestamp('rm_inserted_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.timestamp('rm_modified_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.text('data_source_id').notNullable()
      table.text('batch_id').notNullable().index()
      table.text('deleted')
      table.timestamp('up_to_date', true).notNullable()
      table.json('change_history').defaultTo('[]').notNullable()
      table.text('data_source_uuid').notNullable()
      table.text('rm_property_id').notNullable()
      table.integer('fips_code').notNullable()
      table.text('parcel_id').notNullable()
      table.json('address')
      table.decimal('price', 12, 2)
      table.timestamp('close_date', true)
      table.text('owner_name')
      table.text('owner_name_2')
      table.integer('rm_raw_id').notNullable()
      table.text('inserted').notNullable()
      table.text('updated')
      table.json('shared_groups').notNullable()
      table.json('subscriber_groups').notNullable()
      table.json('hidden_fields').notNullable()
      table.json('ungrouped_fields')
      table.json('owner_address')
      if dataType == 'tax'
        table.integer('bedrooms')
        table.integer('baths_full')
        table.decimal('acres', 11, 3)
        table.integer('sqft_finished')
    .raw("CREATE UNIQUE INDEX ON #{tableName} (data_source_id, data_source_uuid)")
    .raw("CREATE INDEX ON #{tableName} (rm_property_id, deleted, close_date DESC NULLS FIRST)")
    .raw("CREATE TRIGGER update_rm_modified_time_#{tableName} BEFORE UPDATE ON #{tableName} FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column()")


module.exports =
  buildUniqueSubtaskName: buildUniqueSubtaskName
  recordChangeCounts: recordChangeCounts
  activateNewData: activateNewData
  getValidationInfo: getValidationInfo
  normalizeData: normalizeData
  getValues: getValues
  finalizeEntry: finalizeEntry
  manageRawDataStream: manageRawDataStream
  ensureNormalizedTable: ensureNormalizedTable
  DELETE: DELETE
