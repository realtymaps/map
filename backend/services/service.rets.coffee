_ = require 'lodash'
logger = require('../config/logger').spawn('service:rets')
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
keystore = require './service.keystore'
dataSource = require './service.dataSource'
sqlHelpers = require '../utils/util.sql.helpers'
retsHelpers = require '../utils/util.retsHelpers'
mlsConfigService = require './service.mls_config'
moment = require 'moment'
{PartiallyHandledError, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
{validators, validateAndTransformRequest} = require '../utils/util.validation'
Promise = require 'bluebird'

RETS_REFRESHES = 'rets-refreshes'
SEVEN_DAYS_MILLIS = 7*24*60*60*1000


_syncDataCache = (ids, saveCacheImpl) ->
  [type, mlsId, otherIds...] = ids
  now = Date.now()  # save the timestamp of when we started the request
  mlsConfigService.getById(mlsId)
  .catch (err) ->
    throw new PartiallyHandledError(err, "Can't get MLS config for #{mlsId}")
  .then ([mlsConfig]) ->
    logger.debug () -> "_syncDataCache(#{ids.join('/')}): attempting to acquire canonical data"
    retsHelpers[type](mlsConfig, otherIds...)
    .then (data) ->
      if !data?.length
        throw new Error("No canonical RETS data returned: #{ids.join('/')}")
      saveCacheImpl(data, mlsConfig, otherIds...)
    .then () ->
      keystore.setValue(ids.join('/'), now, namespace: RETS_REFRESHES)
    .then () ->
      logger.debug () -> "_syncDataCache(#{ids.join('/')}): data cached successfully"
      return data

_getRetsMetadata = (opts) ->
  {ids, forceRefresh, overrideKey, saveCacheImpl} = opts
  [type, mlsId, otherIds...] = ids
  Promise.try () ->
    if forceRefresh
      logger.debug () -> "_getRetsMetadata(#{ids.join('/')}): forced refresh"
      return true
    keystore.getValue(ids.join('/'), namespace: RETS_REFRESHES, defaultValue: 0)
    .then (lastRefresh) ->
      millisSinceLastRefresh = Date.now() - lastRefresh
      if millisSinceLastRefresh > SEVEN_DAYS_MILLIS
        logger.debug () -> "_getRetsMetadata(#{ids.join('/')}): automatic refresh (last refreshed #{moment.duration(millisSinceLastRefresh).humanize()} ago)"
        return true
      else
        return false
  .then (doRefresh) ->
    if doRefresh
      _syncDataCache(ids, saveCacheImpl)
      .catch isCausedBy(retsHelpers.RetsError), (err) ->
        msg = "Couldn't refresh RETS data cache: #{ids.join('/')}"
        if forceRefresh
          # if user requested a refresh, then make sure they know it failed
          logger.error(msg)
          throw err
        else
          # if we were just automatically attempting the refresh, let it slide
          logger.warn(msg)
    else
      logger.debug () -> "_getRetsMetadata(#{ids.join('/')}): using cached data"
      dataSource[type](mlsId, otherIds.join('/'))
      .then (list) ->
        if !list?.length
          logger.debug () -> "_getRetsMetadata(#{ids.join('/')}): no cached data found"
          _syncDataCache(ids, saveCacheImpl)
          .catch isCausedBy(retsHelpers.RetsError), (err) ->
            logger.error("Couldn't acquire canonical RETS data: #{ids.join('/')}")
            throw err
        else
          return list
  .then (mainList) ->
    if !overrideKey
      return mainList
    logger.debug () -> "_getRetsMetadata(#{ids.join('/')}): applying overrides based on #{overrideKey}"
    dataSource[type](mlsId, otherIds.join('/'), true)
    .then (overrideList) ->
      overrideMap = _.indexBy(overrideList, overrideKey)
      for row in mainList
        for key,value of overrideMap[row[overrideKey]]
          if value?
            row[key] = value
      return mainList


getColumnList = (opts) ->
  {mlsId, databaseId, tableId, forceRefresh} = opts
  logger.debug () -> "getColumnList(), mlsId=#{mlsId}, databaseId=#{databaseId}, tableId=#{tableId}, forceRefresh=#{forceRefresh}"
  saveCacheImpl = (list, mlsConfig, databaseId, tableId) ->
    tables.config.dataSourceFields()
    .where
      data_source_id: mlsConfig.id
      data_list_type: "#{databaseId}/#{tableId}"
    .delete()
    .then () ->
      Promise.map list, (data) ->
        idObj =
          data_source_id: mlsConfig.id
          data_list_type: "#{databaseId}/#{tableId}"
          SystemName: data.SystemName
        sqlHelpers.upsert({idObj, entityObj: data, dbFn: tables.config.dataSourceFields})
  _getRetsMetadata({saveCacheImpl, overrideKey: 'SystemName', ids: ['getColumnList', mlsId, databaseId, tableId], forceRefresh})

getLookupTypes = (opts) ->
  {mlsId, databaseId, lookupId, forceRefresh} = opts
  logger.debug () -> "getLookupTypes(), mlsId=#{mlsId}, databaseId=#{databaseId}, lookupId=#{lookupId}, forceRefresh=#{forceRefresh}"
  saveCacheImpl = (list, mlsConfig, databaseId, lookupId) ->
    tables.config.dataSourceLookups()
    .where
      data_source_id: mlsConfig.id
      data_list_type: databaseId
      LookupName: lookupId
    .delete()
    .then () ->
      Promise.map list, (data) ->
        idObj =
          data_source_id: mlsConfig.id
          data_list_type: databaseId
          LookupName: lookupId
          Value: data.Value
        sqlHelpers.upsert({idObj, entityObj: data, dbFn: tables.config.dataSourceLookups})
  _getRetsMetadata({saveCacheImpl, ids: ['getLookupTypes', mlsId, databaseId, lookupId], forceRefresh})

getDatabaseList = (opts) ->
  {mlsId, forceRefresh} = opts
  logger.debug () -> "getDatabaseList(), mlsId=#{mlsId}, forceRefresh=#{forceRefresh}"
  saveCacheImpl = (list, mlsConfig) ->
    tables.config.dataSourceDatabases()
    .where
      data_source_id: mlsConfig.id
    .delete()
    .then () ->
      Promise.map list, (data) ->
        idObj =
          data_source_id: mlsConfig.id
          ResourceID: data.ResourceID
        sqlHelpers.upsert({idObj, entityObj: data, dbFn: tables.config.dataSourceDatabases})
  _getRetsMetadata({saveCacheImpl, ids: ['getDatabaseList', mlsId], forceRefresh})

getObjectList = (opts) ->
  {mlsId, forceRefresh} = opts
  logger.debug () -> "getObjectList(), mlsId=#{mlsId}, forceRefresh=#{forceRefresh}"
  saveCacheImpl = (list, mlsConfig) ->
    tables.config.dataSourceObjects()
    .where
      data_source_id: mlsConfig.id
    .delete()
    .then () ->
      Promise.map list, (data) ->
        idObj =
          data_source_id: mlsConfig.id
          VisibleName: data.VisibleName
        sqlHelpers.upsert({idObj, entityObj: data, dbFn: tables.config.dataSourceObjects})
  _getRetsMetadata({saveCacheImpl, ids: ['getObjectList', mlsId], forceRefresh})

getTableList = (opts) ->
  {mlsId, databaseId, forceRefresh} = opts
  logger.debug () -> "getTableList(), mlsId=#{mlsId}, databaseId=#{databaseId}, forceRefresh=#{forceRefresh}"
  saveCacheImpl = (list, mlsConfig, databaseId) ->
    tables.config.dataSourceTables()
    .where
      data_source_id: mlsConfig.id
      data_list_type: databaseId
    .delete()
    .then () ->
      Promise.map list, (data) ->
        id =
          data_source_id: mlsConfig.id
          data_list_type: databaseId
          ClassName: data.ClassName
        sqlHelpers.upsert({idObj, entityObj: data, dbFn: tables.config.dataSourceTables})
  _getRetsMetadata({saveCacheImpl, ids: ['getTableList', mlsId, databaseId], forceRefresh})


getDataDump = (mlsId, query) ->
  mlsConfigService.getById(mlsId)
  .then ([mlsConfig]) ->
    if !mlsConfig
      next new ExpressResponse
        alert:
          msg: "Config not found for MLS #{mlsId}, try adding it first"
        404
    else
      validations =
        limit: [validators.integer(min: 1), validators.defaults(defaultValue: 1000)]
      validateAndTransformRequest(query, validations)
      .then (result) ->
        retsHelpers.getDataStream(mlsConfig, result.limit)
      .then (retsStream) ->
        columns = null
        # consider just streaming the file as building up data takes up a considerable amount of memory
        data = []
        new Promise (resolve, reject) ->
          delimiter = null
          csvStreamer = through2.obj (event, encoding, callback) ->
            switch event.type
              when 'data'
                data.push(event.payload[1..-1].split(delimiter))
              when 'delimiter'
                delimiter = event.payload
              when 'columns'
                columns = event.payload
              when 'done'
                resolve(data)
                retsStream.unpipe(csvStreamer)
                csvStreamer.end()
              when 'error'
                reject(event.payload)
                retsStream.unpipe(csvStreamer)
                csvStreamer.end()
            callback()
          retsStream.pipe(csvStreamer)
        .then () ->
          data: data
          options:
            columns: columns
            header: true

module.exports = {
  getColumnList
  getLookupTypes
  getDatabaseList
  getObjectList
  getTableList
  getDataDump
}
