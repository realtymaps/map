_ = require 'lodash'
Promise = require 'bluebird'
errorLib = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
logger = require '../config/logger'
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

getLookupTypes = (lookupId) ->
  query = tables.config.dataSourceLookups()
  .select(
    'LookupName',
    'LongValue',
    'ShortValue',
    'Value'
  )
  .where
    LookupName: lookupId
  .catch errorLib.isUnhandled, (error) ->
    throw new errorLib.PartiallyHandledError(error, "Failed to retrieve lookups for metadata entry #{lookupId}")
  .then (fields) ->
    fields

module.exports =
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
