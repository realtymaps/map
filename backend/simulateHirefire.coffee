hirefire = require('./routes/route.hirefire')
jobQueue = require('./utils/util.jobQueue')
_ = require('lodash')


_intervalHandler = null


runHirefire = () ->
  hirefire.info null, null, (response) ->
    if response.payload?
      console.log()
      console.log(new Date())
      for queue in response.payload
        console.log("    #{queue.name}: #{queue.quantity}")

repeatHirefire = (period=60000) ->
  _intervalHandler = setInterval(runHirefire, period)
  setImmediate console.log
  runHirefire()
  return undefined

cancelHirefire = () ->
  clearInterval(_intervalHandler)


module.exports =
  runHirefire: runHirefire
  repeatHirefire: repeatHirefire
  cancelHirefire: cancelHirefire
  jobQueue: jobQueue
