# keep this at the top so it can load first
require './config/newrelic'


cluster = require './config/cluster'
rimraf = require 'rimraf'


_doStartup = (err) ->
  if err
    throw new Error("Couldn't remove nginx socket: #{err}")

  cluster 'web', {}, () ->
    config = require './config/config'
    logger = require './config/logger'
    if config.MEM_WATCH.IS_ON
      # watch and log any leak (a lot of false positive though)
      memwatch = require 'memwatch-next'
      memwatch.on 'leak', (d) -> logger.error "LEAK: #{JSON.stringify(d)}"

    require '../common/extensions/strings'
    require './extensions/console'
    require './extensions'

    require './config/promisify'
    mkdirp = require 'mkdirp'
    touch = require 'touch'

    require('./config/googleMaps').loadValues()
    .then () ->
      # express configuration
      app = require './config/expressSetup'

      try
        logger.info "Attempting to start backend on port #{config.PORT}"
        app.listen config.PORT, ->
          logger.info "Backend express server listening on port #{config.PORT} in #{config.ENV} mode"
          mkdirp './nginx', ->
            touch.sync('./nginx/app-initialized', force: true)
            logger.info 'App init broadcast'
      catch e
        logger.error "backend failed to start with exception: #{e}"
        throw new Error(e)


if process.env.NGINX_SOCKET_FILENAME
  rimraf("./nginx/#{process.env.NGINX_SOCKET_FILENAME}", _doStartup)
else
  _doStartup()
