app = require '../app.coffee'

app.service 'rmapsMapFactoryTestLoggerService', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("test:map")
.service 'rmapsMapFactoryControlsLogger', (nemSimpleLogger) ->
  nemSimpleLogger.spawn("frontend:map:controls")
.run ($log, rmapsMainOptions) ->
  $log.currentLevel = $log.LEVELS[rmapsMainOptions.map.options.logLevel]
