app = require '../app.coffee'

app.config ($provide, nemSimpleLoggerProvider) ->
  $provide.decorator nemSimpleLoggerProvider.decorator...
.config (nemDebugProvider) ->
  debug = nemDebugProvider.debug
  debug.enable("map:*")
.service 'rmapsMapTestLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("test:map")
.service 'rmapsBaseMapFactoryLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:baseFactory")
.service 'rmapsMapFactoryLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:factory")
.service 'rmapsMapControllerLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:controller")
.service 'rmapsMapControlsLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:controls")
.service 'rmapsMapCacheLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:cache")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
