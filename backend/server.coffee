#require('source-map-support').install()
#require 'coffee-script-mapped'

config = require './config/config'

# monitoring with nodetime
if config.NODETIME
  require('nodetime').profile(config.NODETIME)

# "long stack traces" support
if config.LOGGING.LONG_STACK_TRACES
  require 'longjohn'

# promisify libraries
require './config/promisify'

logger = require './config/logger'

# catch all uncaught exceptions
process.on 'uncaughtException', (err) ->
  logger.error 'Something very bad happened: ', err.message
  logger.error err.stack
  process.exit 1  # because now, you are in unpredictable state!

# watch and log any leak (a lot of false positive though)
memwatch = require 'memwatch'
memwatch.on 'leak', (d) -> logger.error "LEAK: #{JSON.stringify(d)}"


# express configuration
app = require("./config/express")

try
  logger.info "Attempting to start backend on port #{config.PORT}."
  app.listen config.PORT, ->
    logger.info "Backend express server listening on port #{@address().port} in #{config.ENV} mode"
catch e
  logger.error "backend failed to start with exception: #{e}"
  throw new Error(e)