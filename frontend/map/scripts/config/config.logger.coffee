app = require '../app.coffee'
# config = require '../../../../backend/config/config.coffee'
# console.log "\n\n\n####### config.LOGGING.ENABLE:"
# console.log config.LOGGING.ENABLE
# debug = require 'debug'
# logger = require '../../../../backend/config/logger.coffee'

app.config (nemDebugProvider) ->
  debug = nemDebugProvider.debug
.service 'rmapsMapTestLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("test:map")
.service 'rmapsMapControlsLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("frontend:map:controls")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
