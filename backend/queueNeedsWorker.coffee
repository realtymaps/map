hirefire = require('./services/service.hirefire')
logger = require('./config/logger').spawn('queueNeeds')
shutdown = require('./config/shutdown')
config = require './config/config'


_intervalHandler = null


runOnce = () ->
  hirefire.updateQueueNeeds()
  .then (needs) ->
    if needs?
      logger.info('Current queue needs:')
      for queue in needs
        logger.info("    #{queue.name}: #{queue.quantity}")

repeat = (period=config.HIREFIRE.RUN_WINDOW) ->
  _intervalHandler = setInterval(runOnce, period)
  runOnce()
  return undefined

cancelRepeat = () ->
  clearInterval(_intervalHandler)


module.exports = {
  runOnce
  repeat
  cancelRepeat
}



if require.main == module  # run directly, not require()d

  doUpdate = () ->
    runOnce()
    .then () ->
      shutdown.exit()
    .catch (err) ->
      logger.error "Unexpected error updating queue needs: #{err.stack || err}"
      shutdown.exit(error: true)

  # TODO: decide whether we need the above, or can just use `repeat()`
  doUpdate = repeat

  shutdown.setup()
  hirefire.getLastUpdateTimestamp()
  .then (timestamp) ->
    wait = timestamp + config.HIREFIRE.RUN_WINDOW - Date.now()
    if wait > 0
      setTimeout(doUpdate, wait)
    else
      doUpdate()
