app = require '../app.coffee'

module.exports = app.controller 'MainCtrl'.ourNs(), [
  '$scope', 'Logger'.ns(), 'Limits'.ourNs(),
   ($scope, $log, limitsPromise) ->
     limitsPromise.then (limits) ->
       $log.doLog = limits.doLog
]
