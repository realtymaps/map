app = require '../app.coffee'

app.run [
  'uiGmapLogger', 'MainOptions'.ourNs(),
  ($log, MainOptions) ->
    $log.doLog = MainOptions.map.options.doLog
    $log.currentLevel = MainOptions.map.options.logLevel
]
