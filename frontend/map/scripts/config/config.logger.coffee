app = require '../app.coffee'

app.service 'rmapsMapTestLoggerService', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map", 'test')
.service 'rmapsMapControlsLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("map:controls")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
