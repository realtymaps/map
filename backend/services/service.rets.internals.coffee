Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
rets = require 'rets-client'
logger = require('../config/logger').spawn('service:rets:internals')
require '../config/promisify'
memoize = require 'memoizee'


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


getRetsClient = (loginUrl, username, password, static_ip, handler) ->
  _getRetsClientInternalWrapper(loginUrl, username, password, static_ip)
  .then (retsClient) ->
    handler(retsClient)
    .catch errorHandlingUtils.isCausedBy(rets.RetsReplyError), (error) ->
      if error.replyTag in ["MISC_LOGIN_ERROR", "DUPLICATE_LOGIN_PROHIBITED"]
        referenceId = [loginUrl, username, password, static_ip].join('__')
        referenceBuster[referenceId] = (referenceBuster[referenceId] || 0) + 1
      throw error
    .catch errorHandlingUtils.isCausedBy(rets.RetsServerError), (error) ->
      if "#{error.httpStatus}" == "401"
        referenceId = [loginUrl, username, password, static_ip].join('__')
        referenceBuster[referenceId] = (referenceBuster[referenceId] || 0) + 1
      throw error
  .finally () ->
    setTimeout (() -> _getRetsClientInternal.deleteRef(loginUrl, username, password, static_ip)), 60000


module.exports = {
  getRetsClient
}
