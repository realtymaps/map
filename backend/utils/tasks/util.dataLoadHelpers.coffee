dbs = require '../../config/dbs'
tables = require '../../config/tables'
Promise = require 'bluebird'
jobQueue = require '../util.jobQueue'
validation = require '../util.validation'
validatorBuilder = require '../../../common/utils/util.validatorBuilder'
memoize = require 'memoizee'
vm = require 'vm'
_ = require 'lodash'
logger = require '../../config/logger'
sqlHelpers = require '../util.sql.helpers'


DELETE =
  UNTOUCHED: 'untouched'
  INDICATED: 'indicated'
  NONE: 'none'


buildUniqueSubtaskName = (subtask, prefix='raw') ->
  parts = [prefix, subtask.batch_id, subtask.task_name, subtask.data.dataType]
  if subtask.data.rawTableSuffix
    parts.push(subtask.data.rawTableSuffix)
  parts.join('_')


createRawTempTable = (tableName, fields) ->
  dbs.properties.knex.schema.createTable tableName, (table) ->
    table.increments('rm_raw_id').notNullable()
    table.boolean('rm_valid')
    table.text('rm_error_msg')
    for fieldName in fields
      table.text(fieldName.replace(/\./g, ''))


_countInvalidRows = (knex, tableName, assignedFalse) ->
  asPrefix = if assignedFalse then 'invalids' else 'unvalids'
  knex
  .sum('invalid')
  .from () ->
    query = this
    .count('* AS invalid')
    .from(tableName)
    if assignedFalse
      query = query.where(rm_valid: false)
    else
      query = query.whereNull('rm_valid')
    query.as(asPrefix)

    
recordChangeCounts = (subtask) ->
  rawTableName = buildUniqueSubtaskName(subtask)
  subset =
    data_source_id: subtask.task_name
  _.extend(subset, subtask.data.subset)
  Promise.try () ->
    if subtask.data.deletes == DELETE.UNTOUCHED
      # check if any rows will be left active after delete, and error if not; for efficiency, just grab the id of the
      # first such row rather than return all or count them all
      tables.propertyData[subtask.data.dataType]()
      .select('rm_raw_id')
      .where(batch_id: subtask.batch_id)
      .where(subset)
      .whereNull('deleted')
      .limit(1)
      .then (row) ->
        if !row?[0]?
          throw new jobQueue.HardFail("operation would delete all active rows for #{subtask.task_name}")
      .then () ->
        # mark any rows not updated by this task (and not already marked) as deleted -- we only do this when doing a full
        # refresh of all data, because this would be overzealous if we're just doing an incremental update; the update
        # will resolve to a count of affected rows
        tables.propertyData[subtask.data.dataType]()
        .whereNot(batch_id: subtask.batch_id)
        .where(subset)
        .whereNull('deleted')
        .update(deleted: subtask.batch_id)
    else if subtask.data.deletes == DELETE.INDICATED
      tables.propertyData[subtask.data.dataType]()
      .where(subset)
      .where(deleted: subtask.batch_id)
  .then (deletedCount=0) ->
    # get a count of raw rows from all raw tables from this batch with rm_valid == false
    invalidSubquery = () -> _countInvalidRows(this, rawTableName, true)
    # get a count of raw rows from all raw tables from this batch with rm_valid == NULL
    unvalidatedSubquery = () -> _countInvalidRows(this, rawTableName, false)
    # get a count of rows from this batch with null change history, i.e. newly-inserted rows
    insertedSubquery = () ->
      tables.propertyData[subtask.data.dataType](this)
      .where(inserted: subtask.batch_id)
      .where(subset)
      .count('*')
    # get a count of rows from this batch without a null change history, i.e. newly-updated rows
    updatedSubquery = () ->
      tables.propertyData[subtask.data.dataType](this)
      .where(updated: subtask.batch_id)
      .where(subset)
      .count('*')
    touchedSubquery = () ->
      tables.propertyData[subtask.data.dataType](this)
      .where(batch_id: subtask.batch_id)
      .where(subset)
      .orWhere(deleted: subtask.batch_id)
      .where(subset)
      .count('*')
    tables.jobQueue.dataLoadHistory()
    .where(raw_table_name: rawTableName)
    .update
      invalid_rows: invalidSubquery
      unvalidated_rows: unvalidatedSubquery
      inserted_rows: insertedSubquery
      updated_rows: updatedSubquery
      deleted_rows: deletedCount
      touched_rows: touchedSubquery


# this function flips inactive rows to active, active rows to inactive, and deletes now-inactive and extraneous rows
activateNewData = (subtask) ->
  # wrapping this in a transaction improves performance, since we're editing some rows twice
  tables.propertyData.combined.transaction (transaction) ->
    if subtask.data.deletes == DELETE.UNTOUCHED
      # in this mode, we perform those actions to all rows on this data_source_id, because we assume this is a
      # full data sync, and if we didn't touch it that means it should be deleted
      activatePromise = tables.propertyData.combined(transaction)
      .where(data_source_id: subtask.task_name)
      .update(active: tables.propertyData.combined.raw('NOT "active"'))
    else
      # in this mode, we're doing an incremental update, so we only want to perform those actions for rows with an
      # rm_property_id that has been updated in this batch
      activatePromise = tables.propertyData.combined(transaction, 'updater')
      .whereExists () ->
        tables.propertyData.combined(this)
        .select(1)
        .where
          update_source: subtask.task_name
          batch_id: subtask.batch_id
          active: false
          rm_property_id: tables.propertyData.combined.raw("updater.rm_property_id")
          data_source_id: tables.propertyData.combined.raw("updater.data_source_id")
        .as('exister')
      .update(active: tables.propertyData.combined.raw('NOT "active"'))
      
    activatePromise
    .then () ->
      # delete inactive rows
      tables.propertyData.combined(transaction)
      .where
        data_source_id: subtask.task_name
        active: false
      .delete()
    .then () ->
      # delete rows marked explicitly for deletion
      tables.propertyData.combined(transaction, 'deleter')
      .where(data_source_id: subtask.task_name)
      .whereExists () ->
        tables.propertyData.deletes(this)
        .select(1)
        .where
          data_source_id: subtask.task_name
          batch_id: subtask.batch_id
          rm_property_id: tables.propertyData.combined.raw("deleter.rm_property_id")
      .delete()


_getUsedInputFields = (validationDefinition) ->
  if validationDefinition.input?
    if _.isObject validationDefinition.input
      return _.values(validationDefinition.input)
    else
      return validationDefinition.input
  else
    return [validationDefinition.output]


getValidationInfo = (dataSourceType, dataSourceId, dataType) ->
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
    tables.config.dataNormalization()
    .where
      data_source_id: dataSourceId
      data_type: dataType
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
            if validationDefinition.list != 'base' || validationDefinition.output == 'address' || validationDefinition.output == 'status_display'
              usedKeys = usedKeys.concat(_getUsedInputFields(validationDefinition))
            else if validationDefinition.output == 'days_on_market'
              # explicitly exclude these keys from diff, because they are derived values based on date
              diffExcludeKeys = _getUsedInputFields(validationDefinition)
      else if dataSourceType == 'county'
        for groupName, validationList of validationMap
          for validationDefinition in validationList
            # generally, don't count the 'base' fields as being used, but we do for 'address', as the source
            # fields for those don't have to be explicitly reused
            if validationDefinition.list != 'base' || validationDefinition.output == 'address'
              usedKeys = usedKeys.concat(_getUsedInputFields(validationDefinition))
      return {validationMap: validationMap, usedKeys: usedKeys, diffExcludeKeys: diffExcludeKeys}
# memoize it to cache js evals, but only for up to (a bit less than) 15 minutes at a time
getValidationInfo = memoize.promise(getValidationInfo, maxAge: 850000)


# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) -> Promise.try () ->
  rawTableName = buildUniqueSubtaskName(subtask)
  # get rows for this subtask
  rowsPromise = tables.buildQuery('properties', rawTableName)()
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])
  # get validations
  validationPromise = getValidationInfo(options.dataSourceType, options.dataSourceId, subtask.data.dataType)
  # get start time for "last updated" stamp
  startTimePromise = jobQueue.getLastTaskStartTime(subtask.task_name, false)
  Promise.join rowsPromise, validationPromise, startTimePromise, (rows, validationInfo, startTime) ->
    promises = for row in rows then do (row) ->
      stats =
        data_source_id: options.dataSourceId
        batch_id: subtask.batch_id
        rm_raw_id: row.rm_raw_id
        up_to_date: startTime
      Promise.props(_.mapValues(validationInfo.validationMap, validation.validateAndTransform.bind(null, row)))
      .then options.buildRecord.bind(null, stats, validationInfo.usedKeys, row, subtask.data.dataType)
      .then _updateRecord.bind(null, stats, validationInfo.diffExcludeKeys, subtask.data.dataType)
      .then () ->
        tables.buildQuery('properties', rawTableName)()
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: true)
      .catch validation.DataValidationError, (err) ->
        tables.buildQuery('properties', rawTableName)()
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: false, rm_error_msg: err.toString())
    Promise.all promises


_updateRecord = (stats, diffExcludeKeys, dataType, updateRow) -> Promise.try () ->
  # check for an existing row
  tables.propertyData[dataType]()
  .select('*')
  .where
    data_source_uuid: updateRow.data_source_uuid
    data_source_id: updateRow.data_source_id
  .then (result) ->
    if !result?.length
      # no existing row, just insert
      updateRow.inserted = stats.batch_id
      tables.propertyData[dataType]()
      .insert(updateRow)
    else
      # found an existing row, so need to update, but include change log
      result = result[0]
      updateRow.change_history = result.change_history ? []
      changes = _getRowChanges(updateRow, result, diffExcludeKeys)
      if !_.isEmpty changes
        updateRow.change_history.push changes
        updateRow.updated = stats.batch_id
      updateRow.change_history = sqlHelpers.safeJsonArray(tables.propertyData[dataType](), updateRow.change_history)
      tables.propertyData[dataType]()
      .where
        data_source_uuid: updateRow.data_source_uuid
        data_source_id: updateRow.data_source_id
      .update(updateRow)


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
  entry.prior_entries = sqlHelpers.safeJsonArray(tables.propertyData.combined, entries)
  entry.address = sqlHelpers.safeJsonArray(tables.propertyData.combined, entry.address)
  entry.change_history = sqlHelpers.safeJsonArray(tables.propertyData.combined, entry.change_history)
  entry.update_source = entry.data_source_id
  entry


module.exports =
  buildUniqueSubtaskName: buildUniqueSubtaskName
  createRawTempTable: createRawTempTable
  recordChangeCounts: recordChangeCounts
  activateNewData: activateNewData
  getValidationInfo: getValidationInfo
  normalizeData: normalizeData
  getValues: getValues
  finalizeEntry: finalizeEntry
  DELETE: DELETE
