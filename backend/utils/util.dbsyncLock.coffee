Promise = require('bluebird')
logger = require('../config/logger').spawn('dbsyncLock')
keystore = require '../services/service.keystore'


releaseLock = () -> Promise.try () ->
  if !process.env.HEROKU_SLUG_COMMIT
    throw new Error('HEROKU_SLUG_COMMIT variable not set')
  keystore.setValuesMap({status: 'ready', slugId: process.env.HEROKU_SLUG_COMMIT}, namespace: 'dbsyncLock')


waitForUnlock = (delay=5, maxDelay=30) -> Promise.try () ->
  if !process.env.HEROKU_SLUG_COMMIT
    throw new Error('HEROKU_SLUG_COMMIT variable not set')
  keystore.getValuesMap('dbsyncLock', {status: 'locked', slugId: null})
  .then (results) ->
    if results.status == 'ready' && results.slugId == process.env.HEROKU_SLUG_COMMIT
      logger.debug('ready')
      return
    actualDelay = Math.min(delay, maxDelay)
    logger.debug () -> "locked: delaying #{actualDelay}s"
    Promise.delay(actualDelay*1000)
    .then () ->
      waitForUnlock(delay+5)


module.exports = {
  releaseLock
  waitForUnlock
}
