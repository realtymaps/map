Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
logger = require('../config/logger').spawn('task:mls')
tables = require '../config/tables'
retsService = require '../services/service.rets'
dataLoadHelpers = require './util.dataLoadHelpers'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
mlsConfigService = require '../services/service.mls_config'
retsCacheService = require '../services/service.retsCache'
sqlHelpers = require '../utils/util.sql.helpers'


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options={}) ->
  # figure out when we last got updates from this table
  if options.fullRefresh
    updateThresholdPromise = Promise.resolve(0)
  else
    updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  rawTable = tables.temp(subid: dataLoadHelpers.buildUniqueSubtaskName(subtask))
  uuidPromise = getMlsField(options.dataSourceId, 'data_source_uuid', options.dataType)
  offsetPromise = sqlHelpers.checkTableExists(rawTable)
  .then (exists) ->
    if !exists
      return undefined
    rawTable.count('*')
    .then (result) ->
      return parseInt(result[0].count)
  Promise.join updateThresholdPromise, uuidPromise, offsetPromise, (updateThreshold, uuidField, offset) ->
    # don't just try to pick back up exactly where we left off -- add some overlap
    if offset?
      overlappedOffset = offset-Math.max(10, Math.floor(offset*0.01))
    searchOptions = {limit: options.limit, subLimit: options.subLimit, offset: overlappedOffset}
    retsService.getDataStream(options.dataSourceId, options.dataType, minDate: updateThreshold, uuidField: uuidField, searchOptions: searchOptions)
    .catch retsService.isMaybeTransientRetsError, (error) ->
      throw new SoftFail(error, "Transient RETS error; try again later")
    .then (retsStream) ->
      dataLoadHistory =
        data_source_id: options.dataSourceId
        data_source_type: 'mls'
        data_type: options.dataType
        batch_id: subtask.batch_id
        raw_table_name: rawTable.tableName
        raw_rows: offset
      dataLoadHelpers.manageRawDataStream(dataLoadHistory, retsStream, {initialCount: offset, maxChunkSize: 10000})
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTable.tableName}")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to load RETS data for update')


###
# these function works backwards from the validation for `fieldName` (e.g. "data_source_uuid") to determine the LongName and then the
# SystemName of the UUID field
###

getMlsField = (mlsId, rmapsFieldName, dataType) ->
  mlsConfigService.getByIdCached(mlsId)
  .then (mlsInfo) ->
    schemaInfo = mlsInfo["#{dataType}_data"]
    columnDataPromise = retsCacheService.getColumnList(mlsId: mlsId, databaseId: schemaInfo.db, tableId: schemaInfo.table)
    validationInfoPromise = dataLoadHelpers.getValidationInfo('mls', mlsId, dataType, 'base', rmapsFieldName)
    Promise.join columnDataPromise, validationInfoPromise, (columnData, validationInfo) ->
      uuidLongName = validationInfo.validationMap.base?[0]?.input
      if !uuidLongName
        throw new Error("can't locate normalization config for `#{mlsFieldName}` for #{mlsId}")
      for field in columnData
        if field.LongName == uuidLongName
          mlsFieldName = field.SystemName
          break
      if !mlsFieldName
        throw new Error("can't locate SystemName for field with LongName `#{uuidLongName}`, which is configured as `#{mlsFieldName}` for #{mlsId}")
      return mlsFieldName


module.exports = {
  loadUpdates
  getMlsField
}
