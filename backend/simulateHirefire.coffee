hirefire = require('./routes/route.hirefire')
jobQueue = require('./utils/util.jobQueue')
logger = require('./config/logger').spawn('hirefire:simulation')


_intervalHandler = null


runHirefire = () ->
  hirefire.info()
  .then (needs) ->
    if needs?
      logger.info()
      logger.info((new Date()).toString())
      for queue in needs
        logger.info("    #{queue.name}: #{queue.quantity}")

repeatHirefire = (period=60000) ->
  _intervalHandler = setInterval(runHirefire, period)
  setImmediate logger.info
  runHirefire()
  return undefined

cancelHirefire = () ->
  clearInterval(_intervalHandler)


module.exports =
  runHirefire: runHirefire
  repeatHirefire: repeatHirefire
  cancelHirefire: cancelHirefire
  jobQueue: jobQueue
