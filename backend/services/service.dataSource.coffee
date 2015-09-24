_ = require 'lodash'
Promise = require 'bluebird'
errorLib = require '../utils/util.partiallyHandledError'
tables = require '../config/tables'
logger = require '../config/logger'
require '../config/promisify'


getColumnList = (dataSourceId, dataSourceType, dataListType) ->
  query = tables.config.dataSource()
  .select(
    'metadataentryid as MetadataEntryID',
    'systemname as SystemName',
    'shortname as ShortName',
    'longname as LongName',
    'datatype as DataType',
    'interpretation as Interpretation',
    'lookupname as LookupName'
  )
  .where
    data_source_id: dataSourceId
    data_source_type: dataSourceType
    data_list_type: dataListType
  .catch errorLib.isUnhandled, (error) ->
    throw new errorLib.PartiallyHandledError(error, "Failed to retrieve #{dataSourceId} columns")
  .then (response) ->
    response
  .then (fields) ->
    for field in fields
      field.LongName = field.LongName.replace(/\./g, '')
    fields

getLookupTypes = (serverInfo, databaseName, lookupId) ->


module.exports =
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
