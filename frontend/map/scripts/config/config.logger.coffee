app = require '../app.coffee'
debug = require 'debug'
logger = require '../../../../backend/config/logger'

app.config (nemDebugProvider) ->
  #debug = nemDebugProvider.debug
  debug.enable("map:*")
.service 'rmapsMapTestLogger', (nemSimpleLogger) ->
  logger.spawn("test:map")
.service 'rmapsMapControlsLogger', (nemSimpleLogger) ->
  logger.spawn("map:controls")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
