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

_syncDataCacheImpls =
  columns: (mlsConfig, databaseId, tableId) ->
    retsHelpers.getColumnList(mlsConfig, databaseId, tableId)
    .then (list) ->
      tables.config.dataSourceFields()
      .where
        data_source_id: mlsConfig.id
        data_source_type: 'mls'
        data_list_type: "#{databaseId}/#{tableId}"
      .delete()
      .then () ->
        Promise.map list, (columnInfo) ->
          id =
            SystemName: columnInfo.SystemName
            data_source_id: mlsConfig.id
            data_source_type: 'mls'
            data_list_type: "#{databaseId}/#{tableId}"
          sqlHelpers.upsert(id, columnInfo, tables.config.dataSourceFields)
      .then () ->
        return list

_syncDataCache = (ids) ->
  [type, mlsId, otherIds...] = ids
  now = Date.now()  # save the timestamp of when we started the request
  mlsConfigService.getById(mlsId)
  .then ([mlsConfig]) ->
    _syncDataCacheImpls[type](mlsConfig, otherIds...)
  .then (data) ->
    keystore.setValue(ids.join('/'), now, namespace: RETS_REFRESHES)
    .then () ->
      return data


getColumnList = (opts) ->
  {mlsId, databaseId, tableId, forceRefresh} = opts
  @logger.debug () -> "getColumnList(), mlsId=#{mlsId}, databaseId=#{databaseId}, tableId=#{tableId}, forceRefresh=#{forceRefresh}"
  _getRetsMetadata({applyOverrides: true, ids: ['columns', mlsId, databaseId, tableId], forceRefresh})

_getRetsMetadata = (opts) ->
  {ids, forceRefresh, applyOverrides} = opts
  [type, mlsId, otherIds...] = ids
  Promise.try () ->
    if forceRefresh
      return true
    keystore.getValue(ids.join('/'), namespace: RETS_REFRESHES)
    .then (lastRefresh) ->
      if Date.now() - lastRefresh > SEVEN_DAYS_MILLIS
        return true
      else
        return false
  .then (doRefresh) ->
    if doRefresh
      return _syncDataCache(ids)
    else
      dataSource.getColumnList(mlsId, 'mls', otherIds.join('/'))
      .then (list) ->
        if !list?.length
          return _syncDataCache(ids)
        else
          return list
  .then (mainList) ->
    if !applyOverrides
      return mainList
    dataSource.getColumnList(mlsId, 'mls', otherIds.join('/'), true)
    .then (overrideList) ->
      return _applyOverrides(mainList, overrideList)

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
