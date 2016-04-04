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


unhandledRejections = []


setup = (isParentProcess=false) ->
  if !isParentProcess
    process.on 'SIGINT', exit
    process.on 'SIGTERM', exit

  process.on 'uncaughtException', (err) ->
    logger.error 'Something very bad happened!!!  (uncaught exception)'
    logger.error err.stack || err
    exit(error: true)

  process.on 'unhandledRejection', (err, promise) ->
    unhandledRejections.push(promise)
    logger.debug () -> "unhandled rejection detected (total is now #{unhandledRejections.length}): #{err.message}"
    rejectionExit = () ->
      if err.hasOwnProperty('isOperational')  # means it's a knex error
        detail = util.inspect(err, depth: null)
      else
        detail = err.stack || err
      logger.error 'Something very bad happened!!!  (unhandled rejection)'
      logger.error(detail)
      exit(error: true)
    setTimeout((() -> if unhandledRejections.indexOf(promise) != -1 then rejectionExit()), 5000)

  process.on 'rejectionHandled', (promise) ->
    logger.debug () -> "previously unhandled rejection is now handled (total is now #{unhandledRejections.length})"
    unhandledRejections.splice(unhandledRejections.indexOf(promise), 1)

module.exports = {
  onExit
  exit
  setup
}
