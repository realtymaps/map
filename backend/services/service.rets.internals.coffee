Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
rets = require 'rets-client'
logger = require('../config/logger').spawn('service:rets:internals')
require '../config/promisify'
memoize = require 'memoizee'
moment = require('moment')
externalAccounts = require './service.externalAccounts'
mlsConfigService = require './service.mls_config'
analyzeValue = require '../../common/utils/util.analyzeValue'


_getRetsClientInternal = (loginUrl, username, password, static_ip, dummyCounter) ->
  Promise.try () ->
    new rets.Client {
      loginUrl
      username
      password
      proxyUrl: (if static_ip then process.env.PROXIMO_URL else null)}
  .catch errorHandlingUtils.isUnhandled, (error) ->
    _getRetsClientInternal.delete(loginUrl, username, password, static_ip)
    throw new errorHandlingUtils.PartiallyHandledError(error, 'RETS client could not be created')
  .then (retsClient) ->
    logger.debug 'Logging in client ', loginUrl
    retsClient.login()
    .catch errorHandlingUtils.isUnhandled, (error) ->
      _getRetsClientInternal.delete(loginUrl, username, password, static_ip)
      throw new errorHandlingUtils.PartiallyHandledError(error, 'RETS login failed')
# reference counting memoize
_getRetsClientInternal = memoize.promise _getRetsClientInternal,
  refCounter: true
  primitive: true
  dispose: (retsClient) ->
    logger.debug 'Logging out client', retsClient?.urls?.Logout
    retsClient.logout()
# wrap into a reference-counting-buster
referenceBuster = {}
_getRetsClientInternalWrapper = (args...) -> _getRetsClientInternal(args..., referenceBuster[args.join('__')]||0)


getRetsClient = (mlsId, handler) ->
  Promise.join externalAccounts.getAccountInfo(mlsId), mlsConfigService.getByIdCached(mlsId), (creds, serverInfo) ->
    if !creds || !serverInfo
      throw new Error("Can't get MLS config for #{mlsId}: #{err.message || err}")
    _getRetsClientInternalWrapper(creds.url, creds.username, creds.password, serverInfo.static_ip)
    .then (retsClient) ->
      handler(retsClient, serverInfo)
    .catch isTransientRetsError, (error) ->
      referenceId = [serverInfo.url, creds.username, creds.password, serverInfo.static_ip].join('__')
      referenceBuster[referenceId] = (referenceBuster[referenceId] || 0) + 1
      throw error
    .finally () ->
      setTimeout (() -> _getRetsClientInternal.deleteRef(serverInfo.url, creds.username, creds.password, serverInfo.static_ip)), 60000
  .catch (err) ->
    logger.error analyzeValue.getSimpleDetails(err)
    throw new Error("Can't get MLS config for #{mlsId}: #{err.message || err}")


isTransientRetsError = (error) ->
  cause = errorHandlingUtils.getRootCause(error)
  if cause instanceof rets.RetsReplyError && cause.replyTag in ["MISC_LOGIN_ERROR", "DUPLICATE_LOGIN_PROHIBITED", "SERVER_TEMPORARILY_DISABLED"]
    return true
  if cause instanceof rets.RetsServerError && "#{cause.httpStatus }" == "401"
    return true
  return false


buildSearchQuery = (datetimeField, opts) ->
  if opts.fullQuery
    return opts.fullQuery

  criteria = []
  for key,val of opts.criteria
    criteria.push("(#{key}=#{val})")
  if opts.maxDate?
    criteria.push("(#{datetimeField}=#{moment.utc(new Date(opts.maxDate)).format('YYYY-MM-DD[T]HH:mm:ss[Z]')}-)")
  if opts.minDate? || criteria.length == 0  # need to have at least 1 criteria
    criteria.push("(#{datetimeField}=#{moment.utc(new Date(opts.minDate ? 0)).format('YYYY-MM-DD[T]HH:mm:ss[Z]')}+)")
  return criteria.join(" #{opts.booleanOp ? 'AND'} ")  # default to AND, but allow for OR


module.exports = {
  getRetsClient
  isTransientRetsError
  buildSearchQuery
}
