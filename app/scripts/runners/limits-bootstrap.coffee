app = require '../app.coffee'

# anything we set in limits could/should be bootstrapped here
app.run [ 'uiGmapLogger', 'Limits'.ourNs(), ($log, limitsPromise) ->
  limitsPromise.then (limits) ->
    $log.doLog = limits.doLog
]
