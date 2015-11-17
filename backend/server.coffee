config = require './config/config'

require '../common/extensions/strings'
require './config/promisify'
require './extensions'

logger = require './config/logger'
cluster = require './config/cluster'
touch = require 'touch'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'
Promise = require 'bluebird'


if config.MEM_WATCH.IS_ON
  # watch and log any leak (a lot of false positive though)
  memwatch = require 'memwatch-next'
  memwatch.on 'leak', (d) -> logger.error "LEAK: #{JSON.stringify(d)}"


require('./config/googleMaps').loadValues()
.then () ->
  if process.env.NGINX_SOCKET_FILENAME
    rimraf.async("./nginx/#{process.env.NGINX_SOCKET_FILENAME}")
.then () ->
  cluster 'web', {}, () ->
    # express configuration
    app = require './config/express'

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
