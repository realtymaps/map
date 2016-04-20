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
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
validation = require '../utils/util.validation'
Promise = require 'bluebird'

RETS_REFRESHES = 'rets-refreshes'
SEVEN_DAYS_MILLIS = 7*24*60*60*1000


###
  As a whole, this service is a layer in front of util.retsHelpers to cache the results of metadata requests in the db
  and prevent making unnecessary requests to the RETS server (which is a big deal since some of them limit concurrent
  logins).  getDataDump is the exception, as it pulls some data instead of metadata, and does no caching.
###


_decideIfRefreshNecessary = (opts) -> Promise.try () ->
  {callName, mlsId, otherIds, forceRefresh} = opts
  if forceRefresh
    logger.debug () -> "_getRetsMetadata(#{callName}/#{mlsId}/#{otherIds.join('/')}): forced refresh"
    return true
  keystore.getValue("#{callName}/#{mlsId}/#{otherIds.join('/')}", namespace: RETS_REFRESHES, defaultValue: 0)
  .then (lastRefresh) ->
    millisSinceLastRefresh = Date.now() - lastRefresh
    if millisSinceLastRefresh > SEVEN_DAYS_MILLIS
      logger.debug () -> "_getRetsMetadata(#{callName}/#{mlsId}/#{otherIds.join('/')}): automatic refresh (last refreshed #{moment.duration(millisSinceLastRefresh).humanize()} ago)"
      return true
    else
      logger.debug () -> "_getRetsMetadata(#{callName}/#{mlsId}/#{otherIds.join('/')}): no refresh needed"
      return false


_cacheCanonicalData = (opts) ->
  {callName, mlsId, otherIds, cacheSpecs, forceRefresh} = opts
  now = Date.now()  # save the timestamp of when we started the request
  mlsConfigService.getById(mlsId)
  .catch (err) ->
    throw new errorHandlingUtils.PartiallyHandledError(err, "Can't get MLS config for #{mlsId}")
  .then ([mlsConfig]) ->
    logger.debug () -> "_cacheCanonicalData(#{callName}/#{mlsId}/#{otherIds.join('/')}): attempting to acquire canonical data"
    retsHelpers[callName](mlsConfig, otherIds...)
    .then (data) ->
      if !data?.length
        throw new Error("No canonical RETS data returned: #{callName}/#{mlsId}/#{otherIds.join('/')}")
      logger.debug () -> "_cacheCanonicalData(#{callName}/#{mlsId}/#{otherIds.join('/')}): canonical data acquired, caching"
      cacheSpecs.dbFn.transaction (query, transaction) ->
        query
        .where(cacheSpecs.datasetCriteria)
        .delete()
        .map list, (data) ->
          idObj = _.clone(cacheSpecs.datasetCriteria)
          idObj[cacheSpecs.rowKey] = data[cacheSpecs.rowKey]
          entityObj = _.extend({}, data, cacheSpecs.extraEntityFields)
          sqlHelpers.upsert({idObj, entityObj, dbFn: cacheSpecs.dbFn, transaction})
      .then () ->
        keystore.setValue("#{callName}/#{mlsId}/#{otherIds.join('/')}", now, namespace: RETS_REFRESHES)
      .then () ->
        logger.debug () -> "_cacheCanonicalData(#{callName}/#{mlsId}/#{otherIds.join('/')}): data cached successfully"
        return data
  .catch errorHandlingUtils.isCausedBy(retsHelpers.RetsError), (err) ->
    msg = "Couldn't refresh RETS data cache: #{callName}/#{mlsId}/#{otherIds.join('/')}"
    if forceRefresh
      # if user requested a refresh, then make sure they know it failed
      logger.error(msg)
      throw err
    else
      logger.warn(msg)
      return null


_getCachedData = (opts) -> Promise.try () ->
  {callName, mlsId, otherIds} = opts
  logger.debug () -> "_getRetsMetadata(#{callName}/#{mlsId}/#{otherIds.join('/')}): using cached data"
  dataSource[callName](mlsId, otherIds..., getOverrides: false)
  .then (list) ->
    if !list?.length
      logger.debug () -> "_getRetsMetadata(#{callName}/#{mlsId}/#{otherIds.join('/')}): no cached data found"
      throw new Error("Couldn't acquire any RETS data: #{callName}/#{mlsId}/#{otherIds.join('/')}")
    else
      return list


_applyOverrides = (mainList, opts) ->
  {callName, mlsId, otherIds, overrideKey} = opts
  logger.debug () -> "_getRetsMetadata(#{callName}/#{mlsId}/#{otherIds.join('/')}): applying overrides based on #{overrideKey}"
  dataSource[callName](mlsId, otherIds..., getOverrides: true)
  .then (overrideList) ->
    overrideMap = _.indexBy(overrideList, overrideKey)
    for row in mainList
      for key,value of overrideMap[row[overrideKey]]
        if value?
          row[key] = value
    return mainList


_getRetsMetadata = (opts) ->
  {callName, mlsId, otherIds, forceRefresh, overrideKey, cacheSpecs} = opts
  Promise.try () ->
    _decideIfRefreshNecessary(opts)
  .then (doRefresh) ->
    if !doRefresh
      return null
    _cacheCanonicalData(opts)
  .then (canonicalData) ->
    if canonicalData?.length
      return canonicalData
    else
      _getCachedData(opts)
  .then (mainList) ->
    if !overrideKey
      return mainList
    else
      _applyOverrides(mainList, opts)
  .catch errorHandlingUtils.isUnhandled, (err) ->
    throw new errorHandlingUtils.PartiallyHandledError(err, "Error acquiring required RETS data: #{callName}/#{mlsId}/#{otherIds.join('/')}")


# gets metadata (data type, id for a code-to-readable-values map, etc) about the columns available for a given table in
# a given db of a RETS server
getColumnList = (opts) ->
  {mlsId, databaseId, tableId, forceRefresh} = opts
  logger.debug () -> "getColumnList(), mlsId=#{mlsId}, databaseId=#{databaseId}, tableId=#{tableId}, forceRefresh=#{forceRefresh}"
  cacheSpecs =
    datasetCriteria:
      data_source_id: mlsId
      data_list_type: "#{databaseId}/#{tableId}"
    rowKey: 'SystemName'
    extraEntityFields:
      data_source_type: 'mls'
    dbFn: tables.config.dataSourceFields
  _getRetsMetadata({cacheSpecs, overrideKey: 'SystemName', callName: 'getColumnList', mlsId, otherIds: [databaseId, tableId], forceRefresh})


# gets a list of code-to-readable-values mappings for a given database and mapping/lookup id on a RETS server, as would
# be found in the metadata from getColumnList
getLookupTypes = (opts) ->
  {mlsId, databaseId, lookupId, forceRefresh} = opts
  logger.debug () -> "getLookupTypes(), mlsId=#{mlsId}, databaseId=#{databaseId}, lookupId=#{lookupId}, forceRefresh=#{forceRefresh}"
  cacheSpecs =
    datasetCriteria:
      data_source_id: mlsId
      data_list_type: databaseId
      LookupName: lookupId
    rowKey: 'Value'
    extraEntityFields:
      data_source_type: 'mls'
    dbFn: tables.config.dataSourceLookups
  _getRetsMetadata({cacheSpecs, callName: 'getLookupTypes', mlsId, otherIds: [databaseId, lookupId], forceRefresh})


# gets metadata about the databases available on a given RETS server
getDatabaseList = (opts) ->
  {mlsId, forceRefresh} = opts
  logger.debug () -> "getDatabaseList(), mlsId=#{mlsId}, forceRefresh=#{forceRefresh}"
  cacheSpecs =
    datasetCriteria:
      data_source_id: mlsId
    rowKey: 'ResourceID'
    dbFn: tables.config.dataSourceDatabases
  _getRetsMetadata({cacheSpecs, callName: 'getDatabaseList', mlsId, otherIds: [], forceRefresh})


# gets a list of the object (image/video) types available on a given RETS server -- an entity (listing, realtor, etc)
# may have objects associated with it, and they must be requested by type
getObjectList = (opts) ->
  {mlsId, forceRefresh} = opts
  logger.debug () -> "getObjectList(), mlsId=#{mlsId}, forceRefresh=#{forceRefresh}"
  cacheSpecs =
    datasetCriteria:
      data_source_id: mlsId
    rowKey: 'VisibleName'
    dbFn: tables.config.dataSourceObjects
  _getRetsMetadata({cacheSpecs, callName: 'getObjectList', mlsId, otherIds: [], forceRefresh})


# gets metadata about the tables available in a given database on a given RETS server
getTableList = (opts) ->
  {mlsId, databaseId, forceRefresh} = opts
  logger.debug () -> "getTableList(), mlsId=#{mlsId}, databaseId=#{databaseId}, forceRefresh=#{forceRefresh}"
  cacheSpecs =
    datasetCriteria:
      data_source_id: mlsId
      data_list_type: databaseId
    rowKey: 'ClassName'
    dbFn: tables.config.dataSourceTables
  _getRetsMetadata({cacheSpecs, callName: 'getTableList', mlsId, otherIds: [databaseId], forceRefresh})


# this is the thing that's not like the others.  It gets some data from a RETS server based on a query, and returns it
# as an array of row objects plus and array of column names as suitable for passing directly to a csv library we use.
# The intent here is to allow us to get a sample of e.g. 1000 rows of data to look at when figuring out how to configure
# a new MLS
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
        limit: [validation.validators.integer(min: 1), validation.validators.defaults(defaultValue: 1000)]
      validation.validateAndTransformRequest(query, validations)
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
