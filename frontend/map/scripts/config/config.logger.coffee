app = require '../app.coffee'

app.service 'rmapsMapTestLoggerService', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("test:map")
.service 'rmapsMapControlsLoggerService', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("frontend:map:controls")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
