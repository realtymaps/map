hirefire = require('../services/service.hirefire')
jobQueueErrors = require '../utils/errors/util.error.jobQueue'
config = require '../config/config'

logger = require('../config/logger').spawn('workers:queueNeeds')


queueNeeds = () ->
  logger.debug("Executing updateQueueNeeds...")
  hirefire.updateQueueNeeds()
  .catch jobQueueErrors.LockError, (err) ->
    logger.debug("Couldn't get db lock to update queue needs.")
  .then (needs) ->
    if needs?
      logger.debug('Current queue needs:')
      for queue in needs
        logger.debug () -> "    #{queue.name}: #{queue.quantity}"


module.exports = {
  worker: queueNeeds
  interval: config.HIREFIRE.RUN_WINDOW
  silentWait: 2
  gracefulTermination: 5
  kill: 6
  crash: 7
}
