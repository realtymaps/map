# workers should lazy-load their dependencies

queueNeeds = () ->
  hirefire = require('../services/service.hirefire')
  jobQueueErrors = require '../utils/errors/util.error.jobQueue'
  logger = require('../config/logger').spawn('workers:queueNeeds')


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
  interval: 60000  # 1 minute
  silentWait: 5
  gracefulTermination: 8
  kill: 9
  crash: 10
}
