Promise = require('bluebird')
logger = require('../config/logger').spawn('dbsyncLock')
keystore = require '../services/service.keystore'
_ = require 'lodash'


releaseLock = () -> Promise.try () ->
  if !process.env.HEROKU_SLUG_COMMIT
    throw new Error('HEROKU_SLUG_COMMIT variable not set')
  keystore.setValuesMap({status: 'ready', slugId: process.env.HEROKU_SLUG_COMMIT}, namespace: 'dbsyncLock')


waitForUnlock = ({delay, maxDelay, waitMessage, unlockMessage}) ->
  delay ?= 5
  maxDelay ?= 30
  _waitForUnlockImpl({delay, maxDelay, waitMessage, unlockMessage, attempts: 0})

_waitForUnlockImpl = ({delay, maxDelay, waitMessage, unlockMessage, attempts}) -> Promise.try () ->
  if !process.env.HEROKU_SLUG_COMMIT
    throw new Error('HEROKU_SLUG_COMMIT variable not set')
  keystore.getValuesMap('dbsyncLock', {status: 'locked', slugId: null})
  .then (results) ->
    if results.status == 'ready' && results.slugId == process.env.HEROKU_SLUG_COMMIT
      logger.debug('ready')
      if attempts > 0 && unlockMessage
        console.log(unlockMessage)
      return
    actualDelay = Math.min(delay, maxDelay)
    logger.debug () -> "locked: delaying #{actualDelay}s"
    if attempts == 0 && waitMessage
      console.log(waitMessage)
    Promise.delay(actualDelay*1000)
    .then () ->
      _waitForUnlockImpl({delay:delay+5, maxDelay, waitMessage, unlockMessage, attempts: attempts+1})


module.exports = {
  releaseLock
  waitForUnlock
}
