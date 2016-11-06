_ = require 'lodash'
logger = require('../config/logger').spawn('service:rets:internals')
keystore = require './service.keystore'
dataSource = require './service.dataSource'
retsService = require '../services/service.rets'
mlsConfigService = require './service.mls_config'
moment = require 'moment'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
Promise = require 'bluebird'
UnhandledNamedError = require '../utils/errors/util.error.unhandledNamed'
analyzeValue = require '../../common/utils/util.analyzeValue'

RETS_REFRESHES = 'rets-refreshes'
SEVEN_DAYS_MILLIS = 7*24*60*60*1000


decideIfRefreshNecessary = (opts) -> Promise.try () ->
  {callName, mlsId, otherIds, forceRefresh} = opts
  if forceRefresh
    logger.debug () -> "_getRetsMetadata(#{mlsId}/#{callName}/#{otherIds.join('/')}): forced refresh"
    return true
  keystore.getValue("#{mlsId}/#{callName}/#{otherIds.join('/')}", namespace: RETS_REFRESHES, defaultValue: 0)
  .then (lastRefresh) ->
    millisSinceLastRefresh = Date.now() - lastRefresh
    if millisSinceLastRefresh > SEVEN_DAYS_MILLIS
      logger.debug () -> "_getRetsMetadata(#{mlsId}/#{callName}/#{otherIds.join('/')}): automatic refresh (last refreshed #{moment.duration(millisSinceLastRefresh).humanize()} ago)"
      return true
    else
      logger.debug () -> "_getRetsMetadata(#{mlsId}/#{callName}/#{otherIds.join('/')}): no refresh needed"
      return false


cacheCanonicalData = (opts) ->
  {callName, mlsId, otherIds, cacheSpecs, forceRefresh} = opts
  now = Date.now()  # save the timestamp of when we started the request
  logger.debug () -> "cacheCanonicalData(#{mlsId}/#{callName}/#{otherIds.join('/')}): attempting to acquire canonical data"
  queries = []
  retsService[callName](mlsId, otherIds...)
  .then (list) ->
    if !list?.length
      logger.error "cacheCanonicalData(#{mlsId}/#{callName}/#{otherIds.join('/')}): no canonical data returned"
      throw new UnhandledNamedError('RetsDataError', "No canonical data returned for #{mlsId}/#{callName}/#{otherIds.join('/')}")
    logger.debug () -> "cacheCanonicalData(#{mlsId}/#{callName}/#{otherIds.join('/')}): canonical data acquired, caching"
    cacheSpecs.dbFn.transaction (query, transaction) ->
      q = query
      .where(cacheSpecs.datasetCriteria)
      .delete()
      queries.push(q.toString())
      q.then () ->
        Promise.map list, (row) ->
          entity = _.extend(row, cacheSpecs.datasetCriteria, cacheSpecs.extraEntityFields)
          qq = cacheSpecs.dbFn(transaction: transaction)
          .insert(entity)
          queries.push(qq.toString())
          qq
        .all()
    .then () ->
      keystore.setValue("#{mlsId}/#{callName}/#{otherIds.join('/')}", now, namespace: RETS_REFRESHES)
    .then () ->
      logger.debug () -> "cacheCanonicalData(#{mlsId}/#{callName}/#{otherIds.join('/')}): data cached successfully"
      return list
  .catch errorHandlingUtils.isCausedBy(retsService.RetsError), (err) ->
    msg = "Problem making call to RETS server for #{mlsId}: #{err.message}"
    if forceRefresh
      # if user requested a refresh, then make sure they know it failed
      throw new UnhandledNamedError('RetsDataError', msg)
    else
      logger.warn(msg)
      return null
  .catch (err) ->
    logger.error "Couldn't refresh data cache for #{mlsId}/#{callName}/#{otherIds.join('/')}"
    logger.error "@@@@@@@@@@@@@@@@@@@@@@ cacheCanonicalData(#{mlsId}/#{callName}/#{otherIds.join('/')}): queries:\n     #{queries.join('\n     ')}"
    throw err


getCachedData = (opts) -> Promise.try () ->
  {callName, mlsId, otherIds} = opts
  logger.debug () -> "_getRetsMetadata(#{mlsId}/#{callName}/#{otherIds.join('/')}): using cached data"
  dataSource[callName](mlsId, otherIds..., getOverrides: false)
  .then (list) ->
    if !list?.length
      logger.error "_getRetsMetadata(#{mlsId}/#{callName}/#{otherIds.join('/')}): no cached data found"
      throw new UnhandledNamedError('RetsDataError', "No cached data found for #{mlsId}/#{callName}/#{otherIds.join('/')}")
    else
      return list


applyOverrides = (mainList, opts) ->
  {callName, mlsId, otherIds, overrideKey} = opts
  logger.debug () -> "_getRetsMetadata(#{mlsId}/#{callName}/#{otherIds.join('/')}): applying overrides based on #{overrideKey}"
  dataSource[callName](mlsId, otherIds..., getOverrides: true)
  .then (overrideList) ->
    overrideMap = _.indexBy(overrideList, overrideKey)
    for row in mainList
      for key,value of overrideMap[row[overrideKey]]
        if value?
          row[key] = value
    return mainList


module.exports = {
  decideIfRefreshNecessary
  cacheCanonicalData
  getCachedData
  applyOverrides
}
