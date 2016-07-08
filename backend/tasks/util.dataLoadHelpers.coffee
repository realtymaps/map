tables = require '../config/tables'
Promise = require 'bluebird'
validation = require '../utils/util.validation'
validatorBuilder = require '../../common/utils/util.validatorBuilder'
memoize = require 'memoizee'
vm = require 'vm'
_ = require 'lodash'
logger = require('../config/logger').spawn('dataLoadHelpers')
sqlHelpers = require '../utils/util.sql.helpers'
dbs = require '../config/dbs'
{HardFail, SoftFail} = require '../utils/errors/util.error.jobQueue'
copyStream = require 'pg-copy-streams'
utilStreams = require '../utils/util.streams'
through2 = require 'through2'
rets = require 'rets-client'
parcelUtils = require '../utils/util.parcel'
keystore = require '../services/service.keystore'
analyzeValue = require '../../common/utils/util.analyzeValue'
util = require 'util'
moment = require 'moment'
jobQueue = require '../services/service.jobQueue'
mlsConfigService = require '../services/service.mls_config'


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


_updateDataLoadHistory = (deletedCount=0, invalidCount, unvalidatedCount, insertedCount, updatedCount, subid) ->
  tables.jobQueue.dataLoadHistory()
  .where(raw_table_name: tables.temp.buildTableName(subid))
  .update
    invalid_rows: invalidCount ? 0
    unvalidated_rows: unvalidatedCount ? 0
    inserted_rows: insertedCount[0]?.count ? 0
    updated_rows: updatedCount[0]?.count ? 0
    deleted_rows: deletedCount[0]?.count ? 0
    touched_rows: null  # query was too expensive to run


recordChangeCounts = (subtask, opts={}) -> Promise.try () ->
  logger.debug () -> subtask

  subid = buildUniqueSubtaskName(subtask)
  subset =
    data_source_id: subtask.task_name
  _.extend(subset, subtask.data.subset)

  dbs.transaction 'normalized', (transaction) ->

    deletedPromise = Promise.try () ->
      if subtask.data.deletes == DELETE.UNTOUCHED
        # check if any rows will be left active after delete, and error if not; for efficiency, just grab the id of the
        # first such row rather than return all or count them all
        tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid, transaction: transaction)
        .select('rm_raw_id')
        .where(batch_id: subtask.batch_id)
        .where(subset)
        .whereNull('deleted')
        .limit(1)
        .then (row) ->
          if !row?.length
            throw new HardFail("operation would delete all active rows for #{subtask.task_name}")
        .then () ->
          # mark any rows not updated by this task (and not already marked) as deleted -- we only do this when doing a full
          # refresh of all data, because this would be overzealous if we're just doing an incremental update; the update
          # will resolve to a count of affected rows
          tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid, transaction: transaction)
          .whereNot(batch_id: subtask.batch_id)
          .where(subset)
          .whereNull('deleted')
          .update(deleted: subtask.batch_id)
          .then (count) ->
            [count: count]
      else if subtask.data.deletes == DELETE.INDICATED
        tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid, transaction: transaction)
        .count('*')
        .where(subset)
        .where(deleted: subtask.batch_id)
      else if subtask.data.deletes == DELETE.NONE
        [count: 0]
    # get a count of raw rows from all raw tables from this batch with rm_valid == false
    invalidPromise = if subtask.data.skipRawTable then 0 else _countInvalidRows(subid, true)
    # get a count of raw rows from all raw tables from this batch with rm_valid == NULL
    unvalidatedPromise = if subtask.data.skipRawTable then 0 else _countInvalidRows(subid, false)
    # get a count of rows from this batch with null change history, i.e. newly-inserted rows
    insertedPromise = tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid, transaction: transaction)
    .where(inserted: subtask.batch_id)
    .where(subset)
    .count('*')
    # get a count of rows from this batch without a null change history, i.e. newly-updated rows
    updatedPromise = tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid, transaction: transaction)
    .where(updated: subtask.batch_id)
    .where(subset)
    .count('*')
    ### too expensive to run
    touchedPromise = tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid)
    .where(batch_id: subtask.batch_id)
    .where(subset)
    .orWhere(deleted: subtask.batch_id)
    .where(subset)
    .count('*')
    ###

    Promise.join(deletedPromise, invalidPromise, unvalidatedPromise, insertedPromise, updatedPromise, subid, _updateDataLoadHistory)
    .then () ->
      if !subtask.data.indicateDeletes
        return

      tables.normalized[subtask.data.dataType](subid: subtask.data.normalSubid, transaction: transaction)
      .select('rm_property_id')
      .where(subset)
      .whereNot(batch_id: subtask.batch_id)
      .then (results) ->
        # even though it takes place on another db, we want to wait to commit the earlier transaction until the below
        # successfully commits for data safety
        dbs.transaction (mainDbTransaction) ->
          Promise.map results, (r) ->
            markForDelete r.rm_property_id, subtask.task_name, subtask.batch_id,
              deletesTable: opts.deletesTable
              transaction: mainDbTransaction


# this function flips inactive rows to active, active rows to inactive, and deletes now-inactive and extraneous rows
activateNewData = (subtask, {tableProp, transaction} = {}) -> Promise.try () ->
  logger.debug subtask

  tableProp ?= 'combined'

  # wrapping this in a transaction improves performance, since we're editing some rows twice
  dbs.ensureTransaction transaction, 'main', (transaction) ->
    if subtask.data.deletes == DELETE.UNTOUCHED
      # in this mode, we perform those actions to all rows on this data_source_id, because we assume this is a
      # full data sync, and if we didn't touch it that means it should be deleted
      activatePromise = tables.finalized[tableProp](transaction: transaction)
      .where(data_source_id: subtask.task_name)
      .update(active: dbs.get('main').raw('NOT "active"'))
    else
      # in this mode, we're doing an incremental update, so we only want to perform those actions for rows with an
      # rm_property_id that has been updated in this batch
      activatePromise = tables.finalized[tableProp](transaction: transaction, as: 'updater')
      .whereExists () ->
        tables.finalized[tableProp](transaction: this)
        .select(1)
        .where
          data_source_id: dbs.get('main').raw("updater.data_source_id")
          rm_property_id: dbs.get('main').raw("updater.rm_property_id")
          update_source: subtask.task_name
          batch_id: subtask.batch_id
          active: false
      .update(active: dbs.get('main').raw('NOT "active"'))

    activatePromise
    .then () ->
      # delete inactive rows
      tables.finalized[tableProp](transaction: transaction)
      .where
        data_source_id: subtask.task_name
        active: false
      .delete()
    .then () ->
      # delete rows marked explicitly for deletion
      tables.finalized[tableProp](transaction: transaction, as: 'deleter')
      .where(data_source_id: subtask.task_name)
      .whereExists () ->
        tables.deletes[tableProp](transaction: this)
        .select(1)
        .where
          data_source_id: subtask.task_name
          batch_id: subtask.batch_id
          rm_property_id: dbs.get('main').raw("deleter.rm_property_id")
      .delete()
      .then () ->
        # clean up after itself in the deletes table
        tables.deletes[tableProp](transaction: transaction)
        .where
          data_source_id: subtask.task_name
          batch_id: subtask.batch_id
        .delete()
    .then () ->
      setLastUpdateTimestamp(subtask)
    .then () ->
      if subtask.data.setRefreshTimestamp
        setLastRefreshTimestamp(subtask)


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
      mlsConfigService.getByIdCached(dataSourceId)
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
              diffExcludeKeys.concat(_getUsedInputFields(validationDefinition))
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

getRawRows = (subtask, rawSubid) ->
  rawSubid ?= buildUniqueSubtaskName(subtask)
  # get rows for this subtask
  rowsPromise = tables.temp(subid: rawSubid)
  .whereBetween('rm_raw_id', [subtask.data.offset+1, subtask.data.offset+subtask.data.count])

  logger.debug () -> rowsPromise.toString()
  rowsPromise

# normalizes data from the raw data table into the permanent data table
normalizeData = (subtask, options) -> Promise.try () ->
  successes = []
  rawSubid = buildUniqueSubtaskName(subtask)

  # get validations
  validationPromise = getValidationInfo(options.dataSourceType, options.dataSourceId, subtask.data.dataType)
  doNormalization = (rows, validationInfo) ->
    processRow = (row, index, length) ->
      stats =
        data_source_id: options.dataSourceId
        batch_id: subtask.batch_id
        rm_raw_id: row.rm_raw_id
        up_to_date: new Date(subtask.data.startTime)
      validateSingleField = (definitions) ->
        validation.validateAndTransform(row, definitions)
      Promise.props(_.mapValues(validationInfo.validationMap, validateSingleField))
      .cancellable()
      .then (normalizedData) ->
        options.buildRecord(stats, validationInfo.usedKeys, row, subtask.data.dataType, normalizedData)
      .then (updateRow) ->
        # Data in groups does not need to be searchable, so it gets pre-formatted here
        preformat = (group) ->
          for field in group
            if _.isDate field.value
              field.value = moment(field.value).format 'MMMM Do, YYYY'
              logger.debug "Normalized a date #{field.name} = #{field.value}"
            else if !isNaN(Number(field.value)) && field.name.toLowerCase().indexOf('price') != -1
              field.value = "$" + field.value
              logger.debug "Normalized a price #{field.name} = #{field.value}"
            else if _.isBoolean field.value
              field.value = if field.value then 'yes' else 'no'
              logger.debug "Normalized a boolean #{field.name} = #{field.value}"

        for groupName, group of updateRow.shared_groups
          preformat(group)

        for groupName, group of updateRow.subscriber_groups
          preformat(group)

        updateRecord({
          updateRow
          stats
          diffExcludeKeys: validationInfo.diffExcludeKeys
          dataType: subtask.data.dataType
          subid: subtask.data.normalSubid
          dataSourceType: options.dataSourceType
        })
        .then (rm_property_id) ->
          successes.push(rm_property_id)
        #.then () ->
        #  tables.temp(subid: rawSubid)
        #  .where(rm_raw_id: row.rm_raw_id)
        #  .update(rm_valid: true)
        .catch analyzeValue.isKnexError, (err) ->
          jsonData = util.inspect(updateRow, depth: null)
          tables.temp(subid: rawSubid)
          .where(rm_raw_id: row.rm_raw_id)
          .update(rm_valid: false, rm_error_msg: "#{analyzeValue.getSimpleDetails(err)}\nData: #{jsonData}")
      .catch validation.DataValidationError, (err) ->
        tables.temp(subid: rawSubid)
        .where(rm_raw_id: row.rm_raw_id)
        .update(rm_valid: false, rm_error_msg: err.toString())
    Promise.each(rows, processRow)
  Promise.join(getRawRows(subtask, rawSubid), validationPromise, doNormalization)
  .then () ->
    if successes.length == 0
      logger.debug("No successful data updates from #{subtask.task_name} normalize subtask: "+JSON.stringify(i: subtask.data.i, of: subtask.data.of, rawTableSuffix: subtask.data.rawTableSuffix))
      return
    manualData =
      cause: subtask.data.dataType
      i: subtask.data.i
      of: subtask.data.of
      count: successes.length
      values: successes
      normalSubid: subtask.data.normalSubid
    jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "finalizeData", manualData})


# this function mutates the updateRow parameter, and that is by design -- please don't "fix" that without care
updateRecord = (opts) -> Promise.try () ->
  {stats, diffExcludeKeys, diffBooleanKeys, dataType, dataSourceType, subid, updateRow, delay, flattenRows, forceUpdate} = opts
  diffExcludeKeys ?= []
  diffBooleanKeys ?= []
  delay ?= 100
  flattenRows ?= true

  Promise.delay(delay)  #throttle for heroku's sake
  .then () ->
    # check for an existing row
    tables.normalized[dataType](subid: subid)
    .select('*')
    .where
      data_source_id: updateRow.data_source_id
      data_source_uuid: updateRow.data_source_uuid
  .then (result) ->
    if !result?.length
      # no existing row, just insert
      updateRow.inserted = stats.batch_id
      if dataType == 'parcel'
        parcelUtils.prepRowForRawGeom(updateRow)
      tables.normalized[dataType](subid: subid)
      .insert(updateRow)
      .catch analyzeValue.isKnexError, (err) ->
        if err.code == '23505'  # unique constraint
          delete updateRow.inserted
          newOpts = _.clone(opts)
          newOpts.forceUpdate = true
          updateRecord(newOpts)
        else
          throw err
    else
      # found an existing row, so need to update, but include change log
      oldRow = result[0]

      # possibly flatten the rows
      newData = if flattenRows then _flattenRow(updateRow, dataSourceType, dataType) else updateRow
      oldData = if flattenRows then _flattenRow(oldRow, dataSourceType, dataType) else oldRow
      # remove excluded keys
      newData = _.omit(newData, diffExcludeKeys)
      oldData = _.omit(oldData, diffExcludeKeys)
      # do our brand of diff
      changes = _diff(newData, oldData)
      # mask certain changed values with the simple `true` value
      for field in diffBooleanKeys
        if changes.hasOwnProperty(field)
          changes[field] = true

      if oldRow.deleted && updateRow.deleted && oldRow.deleted != updateRow.deleted
        updateRow.deleted = oldRow.deleted
      updateRow.change_history = oldRow.change_history ? []
      if !_.isEmpty(changes)
        updateRow.updated = stats.batch_id
        updateRow.change_history.push changes
      updateRow.change_history = sqlHelpers.safeJsonArray(updateRow.change_history)

      if dataType == 'parcel'
        parcelUtils.prepRowForRawGeom(updateRow)
      tables.normalized[dataType](subid: subid)
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


# Not all row fields are taken into the result, only those that correspond most directly to the source data,
# excluding those that are expected to be date-related derived values (such as DOM and CDOM for MLS listings)
_flattenRow = (row, dataSourceType, dataType) ->
  flattened = {}

  # first get the [{name: x1, value: y1} ...] lists flattened down as {x1: y1, x2: y2, ...}
  for groupName, groupList of row.shared_groups
    getValues(groupList, flattened)
  for groupName, groupList of row.subscriber_groups
    getValues(groupList, flattened)

  # then merge in hidden and ungrouped fields
  _.extend(flattened, row.hidden_fields)
  _.extend(flattened, row.ungrouped_fields)

  # retain the configured base/filter fields
  baseRuleKeys = _.keys(validatorBuilder.getBaseRules(dataSourceType, dataType))
  _.extend(flattened, _.pick(row, baseRuleKeys))
  return flattened


# this performs a diff of 2 sets of data, returning only the changed/new/deleted fields as keys, with the value
# taken from row2 (intended to be the older set)
_diff = (row1, row2) ->
  result = {}
  for fieldName, value1 of row1
    if _.isEqual(value1, row2[fieldName])
      continue
    result[fieldName] = (row2[fieldName] ? null)

  # then get fields missing from row1
  _.extend result, _.omit(row2, Object.keys(row1))


finalizeEntry = ({entries, subtask}) ->
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
  entry.update_source = subtask.task_name
  entry.actual_photo_count = _.keys(entry.photos).length - 1  # photo 0 and 1 are the same
  entry.baths_total = entry.baths?.filter
  entry

_createRawTable = ({promiseQuery, columns, tableName, dataLoadHistory}) ->
  if !_.isArray columns
    columns = [columns]

  promiseQuery(dbs.get('raw_temp').schema.dropTableIfExists(tableName))
  .then () ->
    tables.jobQueue.dataLoadHistory()
    .where(raw_table_name: tableName)
    .delete()
  .then () ->
    tables.jobQueue.dataLoadHistory()
    .insert(dataLoadHistory)
  .then () ->
    promiseQuery('BEGIN TRANSACTION')
  .then () ->
    createRawTable = dbs.get('raw_temp').schema.createTable tableName, (table) ->
      table.increments('rm_raw_id').notNullable()
      table.boolean('rm_valid')
      table.text('rm_error_msg')
      for fieldName in columns
        table.text(fieldName)
    promiseQuery(createRawTable.toString().replace('"rm_raw_id" serial primary key,', '"rm_raw_id" serial,'))

_endRawTable = ({startedTransaction, count, tableName, promiseQuery}) ->
  if startedTransaction
    promiseQuery("CREATE INDEX ON \"#{tableName}\" (rm_raw_id)")
    .then () ->
      promiseQuery("CREATE INDEX ON \"#{tableName}\" (rm_valid)")
    .then () ->
      promiseQuery('COMMIT TRANSACTION')
    .then () ->
      tables.jobQueue.dataLoadHistory()
      .where(raw_table_name: tableName)
      .update(raw_rows: count)
    .then () ->
      return count
  else
    return count

rollback = ({err, tableName, promiseQuery}) ->
  logger.error("problem streaming to #{tableName}: #{err}")
  promiseQuery('ROLLBACK TRANSACTION')
  .then () ->
    tables.jobQueue.dataLoadHistory()
    .where(raw_table_name: tableName)
    .delete()
  .catch () ->
    throw err
  .then () ->
    throw err


manageRawJSONStream = ({tableName, dataLoadHistory, jsonStream, column}) -> Promise.try ->
  #one column to dump the whole json blob to
  isFinished = false
  count = 0

  objectStreamTransform = (json, encoding, callback) ->
    # logger.debug json
    if isFinished
      return
    count++

    this.push(type: 'data', payload: [JSON.stringify json])
    callback()

  #format the json to a format compatible for manageRawDataStream
  #format: row of strings
  objectStreamer = through2.obj objectStreamTransform, (callback) ->
    if isFinished
      return
    isFinished = true
    logger.debug "FINISHED: #{tableName}"
    objectStreamer.push(type: 'done', payload: count)
    callback()

  objectStreamer.push(type: 'delimiter', payload: '\t')
  objectStreamer.push(type: 'columns', payload: [column])

  jsonStream.once 'error', (err) ->
    if isFinished
      return
    isFinished = true
    objectStreamer.push(type: 'error', payload: err)

  jsonStream.pipe(objectStreamer)

  manageRawDataStream(tableName, dataLoadHistory, objectStreamer)


manageRawDataStream = (tableName, dataLoadHistory, objectStream) ->
  dbs.getPlainClient 'raw_temp', (promiseQuery, streamQuery) ->
    startedTransaction = false
    new Promise (resolve, reject) ->
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
      doPerValEscape = (val) ->
        utilStreams.pgStreamEscape(val, delimiter)
      dbStreamTransform = (event, encoding, callback) ->
        try
          switch event.type
            when 'data'
              if Array.isArray(event.payload)  # escape each value separately
                this.push(_.map(event.payload, doPerValEscape).join(delimiter))
              else  # escape the whole row at once
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
              _createRawTable({promiseQuery, columns, tableName, dataLoadHistory})
              .then () ->
                startedTransaction = true
              .then () ->
                copyStart = "COPY \"#{tableName}\" (\"#{columns.join('", "')}\") FROM STDIN WITH (ENCODING 'UTF8', NULL '', DELIMITER '#{delimiter}')"
                dbStream = streamQuery(copyStream.from(copyStart))
                dbStreamer.pipe(dbStream)
                callback()
            when 'done'
              donePayload = event.payload
              callback()
            when 'error'
              if !(event.payload instanceof rets.RetsReplyError) || event.payload.replyTag != "NO_RECORDS_FOUND"
                # make sure it is a true error, not just no records returned
                onError(event.payload)
              callback()
            else
              callback()
        catch error
          onError(error)
          callback()
      dbStreamer = through2.obj dbStreamTransform, (callback) ->
        if startedTransaction
          this.push('\\.\n')
        callback()
        if !hadError
          resolve(donePayload||0)
      objectStream.pipe(dbStreamer)
    .catch (err) ->
      rollback({err, tableName, promiseQuery})
    .then (count) ->
      _endRawTable({startedTransaction, count, tableName, promiseQuery})


ensureNormalizedTable = (dataType, subid) ->
  tableName = tables.normalized[dataType].buildTableName(subid)
  checkTableExists('normalized', tableName)
  .then (tableAlreadyExists) ->
    if tableAlreadyExists
      return
    createTable = dbs.get('normalized').schema.createTable tableName, (table) ->
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
        table.json('baths')
        table.decimal('acres', 11, 3)
        table.integer('sqft_finished')
        table.json('year_built')
        table.json('promoted_values')
      if dataType == 'tax' || dataType == 'deed'
        table.text('property_type')
        table.text('zoning')
        table.text('legal_unit_number')
    .raw("CREATE UNIQUE INDEX ON #{tableName} (data_source_id, data_source_uuid)")
    .raw("CREATE TRIGGER update_rm_modified_time_#{tableName} BEFORE UPDATE ON #{tableName} FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column()")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, inserted)")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, deleted)")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, fips_code, deleted)")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, updated)")
    if dataType == 'tax'
      createTable = createTable.raw("CREATE INDEX ON #{tableName} (rm_property_id, data_source_id, deleted, close_date DESC NULLS LAST)")
      .raw("CREATE INDEX ON #{tableName} (rm_property_id)")
      .raw("CREATE INDEX ON #{tableName} (data_source_id, fips_code, parcel_id)")
    else
      createTable = createTable.raw("CREATE INDEX ON #{tableName} (rm_property_id, data_source_id, deleted, close_date ASC NULLS FIRST)")
      .raw("CREATE INDEX ON #{tableName} (data_source_id, fips_code, data_source_uuid)")


getLastUpdateTimestamp = (subtask) ->
  keystore.getValue(subtask.task_name, namespace: 'data update timestamps', defaultValue: 0)

setLastUpdateTimestamp = (subtask) ->
  keystore.setValue(subtask.task_name, subtask.data.startTime, namespace: 'data update timestamps')

getLastRefreshTimestamp = (subtask) ->
  keystore.getValue(subtask.task_name, namespace: 'data refresh timestamps', defaultValue: 0)

setLastRefreshTimestamp = (subtask) ->
  keystore.setValue(subtask.task_name, subtask.data.startTime, namespace: 'data refresh timestamps')

# this is logic that checks to see if the last time something happened was before today, and if it is currently after a
# given time of day (24-hour time).  Note this works based on eastern time zone, including DST
checkReadyForRefresh = (subtask, {targetHour, targetMinute}) ->
  targetHour ?= 0
  targetMinute ?= 0
  getLastRefreshTimestamp(subtask)
  .then (refreshTimestamp) ->
    now = Date.now()
    utcOffset = -(new Date()).getTimezoneOffset()/60  # this was in minutes in the wrong direction, we need hours in the right direction

    target = moment.utc(now).utcOffset(utcOffset).startOf('day')
    if target.diff(refreshTimestamp) <= 0  # was today
      return false

    target.hour(targetHour)
    target.minute(targetMinute)
    if target.diff(now) > 0  # not yet past target time
      return false

    return true



checkTableExists = (db, tableName) ->
  dbs.get(db)
  .select(1)
  .from('pg_catalog.pg_class')
  .where
    relname: tableName
    relkind: 'r'
  .then (check=[]) ->
    return check.length > 0


markForDelete = (rm_property_id, data_source_id, batch_id, opts={}) ->
  deletesTable = opts.deletesTable ? 'combined'
  transaction = opts.transaction ? undefined

  tables.deletes[deletesTable](transaction: transaction)
  .returning('rm_property_id')
  .insert({rm_property_id, data_source_id, batch_id})


module.exports = {
  buildUniqueSubtaskName
  recordChangeCounts
  activateNewData
  getValidationInfo
  normalizeData
  getRawRows
  getValues
  finalizeEntry
  manageRawDataStream
  manageRawJSONStream
  ensureNormalizedTable
  DELETE
  rollback
  updateRecord
  getLastUpdateTimestamp
  setLastUpdateTimestamp
  setLastRefreshTimestamp
  getLastRefreshTimestamp
  checkReadyForRefresh
  checkTableExists
  markForDelete
}
