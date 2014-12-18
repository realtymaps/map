app = require '../app.coffee'

app.run [
  'Logger'.ourNs(), 'uiGmapLogger', 'MainOptions'.ourNs(),
  ($log, uiGmapLogger, MainOptions) ->
    uiGmapLogger.currentLevel = $log.LEVELS[MainOptions.map.options.uiGmapLogLevel]
    $log.currentLevel = $log.LEVELS[MainOptions.map.options.logLevel]
]
