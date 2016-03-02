Promise = require 'bluebird'
logger = require('./logger').spawn('shutdown')


exitHandlers = []
onExit = (handler) ->
  exitHandlers.push(handler)

exiting = false
exit = (opts={}) ->
  if exiting
    return
  exiting = true

  setTimeout () ->
    logger.warn "Exit timeout exceeded, forcing exit"
    process.exit(if opts.error then 1 else 0)
  , 9000

  logger.debug "Process exit initiated..."
  Promise.join(exitHandlers)
  .then () ->
    require('./dbs').shutdown(!opts.error)
  .catch (err) ->
    logger.error "Caught error during shutdown: #{err.stack||err}"
  .finally () ->
    logger.debug "... exiting now"
    process.exit(if opts.error then 1 else 0)

  return undefined


setup = (isParentProcess) ->
  if !isParentProcess
    process.on 'SIGINT', exit
    process.on 'SIGTERM', exit

  process.on 'uncaughtException', (err) ->
    logger.error 'Something very bad happened!!!  (uncaught exception)'
    logger.error err.stack || err
    exit(error: true)

  process.on 'unhandledRejection', (err) ->
    logger.error 'Something very bad happened!!!  (unhandled rejection)'
    logger.error err.stack || err
    exit(error: true)


module.exports = {
  onExit
  exit
  setup
}
