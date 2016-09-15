moment = require 'moment'

jobQueue = require './service.jobQueue'
keystore = require './service.keystore'
logger = require('../config/logger').spawn('hirefire')
config = require '../config/config'


NAMESPACE = 'hirefire'
RUN_TIMESTAMP = 'last run timestamp'
QUEUE_NEEDS = 'queue needs'


updateQueueNeeds = () ->
  logger.debug('Doing maintenance...')
  jobQueue.doMaintenance()
  .then () ->
    logger.debug('Queueing ready tasks...')
    jobQueue.queueReadyTasks(dieOnMissingTask: false)
  .then () ->
    logger.debug('Determining queue needs...')
    now = Date.now()
    jobQueue.getQueueNeeds()
    .then (needs) ->
      store = {}
      store[RUN_TIMESTAMP] = now
      store[QUEUE_NEEDS] = needs
      keystore.setValuesMap(store, namespace: NAMESPACE)
      .then () ->
        needs

getQueueNeeds = () ->
  defaults = {}
  defaults[RUN_TIMESTAMP] = 0
  defaults[QUEUE_NEEDS] = []
  keystore.getValuesMap(NAMESPACE, defaultValues: defaults)
  .then (result) ->
    interval = Date.now() - result[RUN_TIMESTAMP]
    if interval > config.HIREFIRE.WARN_THRESHOLD
      logger.warn "Queue needs haven't been refreshed in #{moment.duration(interval).humanize()} (last refresh: #{moment((new Date(result[RUN_TIMESTAMP])).toISOString(), moment.ISO_8601).local().format('ddd, MMM DD YYYY, hh:mm:ss a (Z)')})"
    logger.spawn('needs').debug () -> ('Queue needs: '+JSON.stringify(result[QUEUE_NEEDS], null, 2))
    result[QUEUE_NEEDS]

getLastUpdateTimestamp = () ->
  keystore.getValuesMap(NAMESPACE)
  .then (result) ->
    result[RUN_TIMESTAMP] || 0

module.exports = {
  updateQueueNeeds
  getQueueNeeds
  getLastUpdateTimestamp
}
