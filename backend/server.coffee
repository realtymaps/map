# monitoring with nodetime
if process.env.NODE_ENV == 'production'
  require('nodetime').profile(
    accountKey: "ENTER-A-VALID-KEY-HERE"
    appName: 'mean.coffee'
  )

# dependencies
config = require './config/config'
logger = require './config/logger'
express = require 'express'
passport = require 'passport'
knex = require 'knex'
bookshelf = require 'bookshelf'

root_path = __dirname

# catch all uncaught exceptions
process.on 'uncaughtException', (err) ->
  logger.error 'Something very bad happened: ', err.message
  logger.error err.stack
  process.exit 1  # because now, you are in unpredictable state!

# watch and log any leak (a lot of false positive though)
memwatch = require 'memwatch'
memwatch.on 'leak', (d) -> logger.error "LEAK: #{JSON.stringify(d)}"


# bootstrap databases
dbs =
  users: bookshelf(knex(config.USER_DB_CONFIG))
  properties: bookshelf(knex(config.PROPERTY_DB_CONFIG))

# bootstrap models
require('./models')()

# bootstrap passport config
require('./config/passport')(passport)

# express configuration
app = require("./config/express")(passport, dbs, logger, root_path)

# JWI: is the below redundant with the similar call in config/express.coffee?  
# bootstrap routes
#require("./routes")(app)

# start the app
app.listen app.get('port'), ->
  logger.info "mean.coffee server listening on port #{@address().port} in #{config.ENV} mode"

