_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'


class DataSourceService extends ServiceCrud

  getColumnList: (dataSourceId, dataSourceType, dataListType) ->
    @debug "getColumnList(), dataSourceId=#{dataSourceId}, dataSourceType=#{dataSourceType}, dataListType=#{dataListType}"
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
    @custom(query)

  getLookupTypes: (dataSourceId, lookupId) ->
    @debug "getColumnList(), dataSourceId=#{dataSourceId}, dataSourceType=#{dataSourceType}, dataListType=#{dataListType}"
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
    @custom(query)

module.exports = new DataSourceService tables.config.dataSourceFields,
  idKey: "MetadataEntryID"
  debug: true






# _ = require 'lodash'
# crudService = require '../utils/crud/util.crud.service.helpers'
# Promise = require 'bluebird'
# errorLib = require '../utils/errors/util.error.partiallyHandledError'
# tables = require '../config/tables'
# require '../config/promisify'


# class DataSourceService extends crudService.Crud

#   getColumnList: (dataSourceId, dataSourceType, dataListType) ->
#     query = tables.config.dataSourceFields()
#     .select(
#       'MetadataEntryID',
#       'SystemName',
#       'ShortName',
#       'LongName',
#       'DataType',
#       'Interpretation',
#       'LookupName'
#     )
#     .where
#       data_source_id: dataSourceId
#       data_source_type: dataSourceType
#       data_list_type: dataListType
#     .catch errorLib.isUnhandled, (error) ->
#       throw new errorLib.PartiallyHandledError(error, "Failed to retrieve #{dataSourceId} columns")

#   getLookupTypes: (dataSourceId, lookupId) ->
#     query = tables.config.dataSourceLookups()
#     .select(
#       'LookupName',
#       'LongValue',
#       'ShortValue',
#       'Value'
#     )
#     .where
#       LookupName: lookupId
#       data_source_id: dataSourceId
#     .catch errorLib.isUnhandled, (error) ->
#       throw new errorLib.PartiallyHandledError(error, "Failed to retrieve lookups for metadata entry #{lookupId}, #{dataSourceId}")
#     .then (fields) ->
#       fields

# instance = new DataSourceService(tables.config.dataSourceFields, "MetadataEntryID")

# module.exports = instance
