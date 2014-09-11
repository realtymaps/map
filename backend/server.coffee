#require('source-map-support').install()
#require 'coffee-script-mapped'

config = require './config/config'

# monitoring with nodetime
if config.USE_NODETIME
  require('nodetime').profile(
    accountKey: "ENTER-A-VALID-KEY-HERE"
    appName: 'mean.coffee'
  )

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


# bootstrap passport config
require('./config/passport')

# express configuration
app = require("./config/express")

# JWI: is the below redundant with the similar call in config/express.coffee?  
# bootstrap routes
#require("./routes")(app)
try
  logger.info "attempting to start backend"
  app.listen app.get('port'), ->
    logger.info "backend express server listening on port #{@address().port} in #{config.ENV} mode"
catch e then logger.info "backend failed to start with exception: #{e}"