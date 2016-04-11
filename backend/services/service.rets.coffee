_ = require 'lodash'
logger = require('../config/logger').spawn('service:rets')
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
keystore = require './service.keystore'
dataSource = require './service.dataSource'
sqlHelpers = require '../utils/util.sql.helpers'
retsHelpers = require '../utils/util.retsHelpers'
mlsConfigService = require './service.mls_config'

RETS_REFRESHES = 'rets-refreshes'
SEVEN_DAYS_MILLIS = 7*24*60*60*1000


_applyOverrides = (mainData, overrideData) ->
  overrideMap = _.indexBy(overrideData, 'SystemName')
  for row in mainData
    for key,value of overrideMap[row.SystemName]
      if value?
        row[key] = value
  return mainData

_syncColumnData = ({mlsId, databaseId, tableId}) ->
  now = Date.now()  # save the timestamp of when we started the request
  mlsConfigService.getById(mlsId)
  .then ([mlsConfig]) ->
    retsHelpers.getColumnList(mlsConfig, databaseId, tableId)
  .then (list) ->
    tables.config.dataSourceFields()
    .where
      data_source_id: mlsId
      data_source_type: 'mls'
      data_list_type: "#{databaseId}/#{tableId}"
    .delete()
    .then () ->
      Promise.map list, (columnInfo) ->
        id =
          SystemName: columnInfo.SystemName
          data_source_id: mlsId
          data_source_type: 'mls'
          data_list_type: "#{databaseId}/#{tableId}"
        sqlHelpers.upsert(id, columnInfo, tables.config.dataSourceFields)
    .then () ->
      keystore.setValue("columns/#{mlsId}/#{databaseId}/#{tableId}", now, namespace: RETS_REFRESHES)
    .then () ->
      return list



getColumnList = (opts) ->
  {mlsId, databaseId, tableId, forceRefresh} = opts
  @logger.debug () -> "getColumnList(), mlsId=#{mlsId}, databaseId=#{databaseId}, tableId=#{tableId}, forceRefresh=#{forceRefresh}"
  Promise.try () ->
    if forceRefresh
      return true
    keystore.getValue("columns/#{mlsId}/#{databaseId}/#{tableId}", namespace: RETS_REFRESHES)
    .then (lastRefresh) ->
      if Date.now() - lastRefresh > SEVEN_DAYS_MILLIS
        return true
      else
        return false
  .then (doRefresh) ->
    if doRefresh
      _syncColumnData(opts)
    else
      dataSource.getColumnList(mlsId, 'mls', "#{databaseId}/#{tableId}")
      .then (list) ->
        if !list?.length
          return _syncColumnData(opts)
        else
          return list



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

getLookupTypes = (dataSourceId, lookupId) ->
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


module.exports = {
  getColumnList
  getLookupTypes
}
