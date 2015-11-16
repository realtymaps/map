_ = require 'lodash'
Promise = require 'bluebird'
errorLib = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
require '../config/promisify'


getColumnList = (dataSourceId, dataSourceType, dataListType) ->
  query = tables.config.dataSourceFields()
  .select(
    'MetadataEntryID',
    'SystemName',
    'ShortName',
    'LongName',
    'DataType',
    'Interpretation',
    'LookupName'
  )
  .where
    data_source_id: dataSourceId
    data_source_type: dataSourceType
    data_list_type: dataListType
  .catch errorLib.isUnhandled, (error) ->
    throw new errorLib.PartiallyHandledError(error, "Failed to retrieve #{dataSourceId} columns")
  .then (fields) ->
    for field in fields
      field.LongName = field.LongName.replace(/\./g, '')
    fields

getLookupTypes = (dataSourceId, lookupId) ->
  query = tables.config.dataSourceLookups()
  .select(
    'LookupName',
    'LongValue',
    'ShortValue',
    'Value'
  )
  .where
    LookupName: lookupId
    data_source_id: dataSourceId
  .catch errorLib.isUnhandled, (error) ->
    throw new errorLib.PartiallyHandledError(error, "Failed to retrieve lookups for metadata entry #{lookupId}, #{dataSourceId}")
  .then (fields) ->
    fields

module.exports =
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
