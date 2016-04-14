_ = require 'lodash'
logger = require('../config/logger').spawn('service:dataSource')
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
Promise = require 'bluebird'


commonColumnFields = [
  'ShortName',
  'LongName',
  'DataType',
  'Interpretation',
  'LookupName'
]
regularColumnFields = ['MetadataEntryID', 'SystemName'].concat(commonColumnFields)
overrideColumnFields = ['overrides AS SystemName'].concat(commonColumnFields)

class DataSourceService extends ServiceCrud

  getColumnList: (dataSourceId, dataListType, getOverrides=false) ->
    @logger.debug () -> "getColumnList(), dataSourceId=#{dataSourceId}, dataListType=#{dataListType}, getOverrides=#{getOverrides}"
    query = tables.config.dataSourceFields()
    .select(if getOverrides then overrideColumnFields else regularColumnFields)
    .where
      data_source_id: dataSourceId
      data_list_type: dataListType

    if getOverrides
      query = query.whereNotNull('overrides')
    else
      query = query.whereNull('overrides')

    return @custom(query)


  getLookupTypes: (dataSourceId, lookupId) ->
    @logger.debug () -> "getLookupTypes(), dataSourceId=#{dataSourceId}, lookupId=#{lookupId}"
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

  getDatabaseList: (dataSourceId) ->
    @logger.debug () -> "getDatabaseList(), dataSourceId=#{dataSourceId}"
    query = tables.config.dataSourceDatabases()
    .select(
      "ResourceID",
      "StandardName",
      "VisibleName",
      "ObjectVersion"
    )
    .where
      data_source_id: dataSourceId
    @custom(query)

  getObjectList: (dataSourceId) ->
    @logger.debug () -> "getObjectList(), dataSourceId=#{dataSourceId}"
    query = tables.config.dataSourceObjects()
    .select(
      "VisibleName"
    )
    .where
      data_source_id: dataSourceId
    @custom(query)

  getTableList: (dataSourceId) ->
    @logger.debug () -> "getTableList(), dataSourceId=#{dataSourceId}"
    query = tables.config.dataSourceTables()
    .select(
      "ClassName",
      "StandardName",
      "VisibleName",
      "ObjectVersion"
    )
    .where
      data_source_id: dataSourceId
      data_list_type: dataListType
    @custom(query)


module.exports = new DataSourceService tables.config.dataSourceFields,
  idKey: "MetadataEntryID"
