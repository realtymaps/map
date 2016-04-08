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

  getColumnList: (dataSourceId, dataSourceType, dataListType, getOverrides=false) ->
    @logger.debug () -> "getColumnList(), dataSourceId=#{dataSourceId}, dataSourceType=#{dataSourceType}, dataListType=#{dataListType}, getOverrides=#{getOverrides}"
    query = tables.config.dataSourceFields()
    .select(if getOverrides then overrideColumnFields else regularColumnFields)
    .where
      data_source_id: dataSourceId
      data_source_type: dataSourceType
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

module.exports = new DataSourceService tables.config.dataSourceFields,
  idKey: "MetadataEntryID"
