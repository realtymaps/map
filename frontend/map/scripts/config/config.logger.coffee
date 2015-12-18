app = require '../app.coffee'

app.config (nemDebugProvider) ->
  debug = nemDebugProvider.debug
  debug.enable("map:*")
.service 'rmapsMapTestLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("test:map")
.service 'rmapsMapControlsLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:controls")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
