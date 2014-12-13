app = require '../app.coffee'

app.run [
  'uiGmapLogger', 'MainOptions'.ourNs(),
  ($log, MainOptions) ->
    $log.currentLevel = $log.LEVELS[MainOptions.map.options.logLevel]
]
