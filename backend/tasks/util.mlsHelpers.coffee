Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
logger = require('../config/logger').spawn('task:mls')
tables = require '../config/tables'
retsService = require '../services/service.rets'
dataLoadHelpers = require './util.dataLoadHelpers'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
mlsConfigService = require '../services/service.mls_config'
retsCacheService = require '../services/service.retsCache'


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options={}) ->
  # figure out when we last got updates from this table
  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  uuidPromise = getMlsField(options.dataSourceId, 'data_source_uuid', options.dataType)
  Promise.join updateThresholdPromise, uuidPromise, (updateThreshold, uuidField) ->
    retsService.getDataStream(options.dataSourceId, options.dataType, minDate: updateThreshold, uuidField: uuidField, searchOptions: {limit: options.limit})
    .catch retsService.isMaybeTransientRetsError, (error) ->
      throw new SoftFail(error, "Transient RETS error; try again later")
    .then (retsStream) ->
      rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))
      dataLoadHistory =
        data_source_id: options.dataSourceId
        data_source_type: 'mls'
        data_type: subtask.data.dataType
        batch_id: subtask.batch_id
        raw_table_name: rawTableName
      dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, retsStream)
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to load RETS data for update')


###
# these function works backwards from the validation for `fieldName` (e.g. "data_source_uuid") to determine the LongName and then the
# SystemName of the UUID field
###

getMlsField = (mlsId, rmapsFieldName, dataType) ->
  schemaInfo = mlsInfo["#{dataType}_data"]
  mlsConfigService.getByIdCached(mlsId)
  .then (mlsInfo) ->
    columnDataPromise = retsCacheService.getColumnList(mlsId: mlsId, databaseId: schemaInfo.db, tableId: schemaInfo.table)
    validationInfoPromise = dataLoadHelpers.getValidationInfo('mls', mlsId, dataType, 'base', rmapsFieldName)
    Promise.join columnDataPromise, validationInfoPromise, (columnData, validationInfo) ->
      for field in columnData
        if field.LongName == validationInfo.validationMap.base[0].input
          mlsFieldName = field.SystemName
          break
      if !mlsFieldName
        throw new Error("can't locate `#{mlsFieldName}` for #{mlsId} (SystemName for #{validationInfo.validationMap.base[0].input})")
      return mlsFieldName


module.exports = {
  loadUpdates
  getMlsField
}
