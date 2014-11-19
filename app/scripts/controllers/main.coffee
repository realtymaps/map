app = require '../app.coffee'

require '../runners/run-templates.coffee'
require '../runners/run.coffee'
require '../config/location.coffee'
require '../config/on-root-scope.coffee'
require '../config/routes.coffee'

module.exports = app.controller 'MainCtrl'.ourNs(), [
  '$scope', 'uiGmapLogger', 'Limits'.ourNs(),
   ($scope, $log, limitsPromise) ->
     limitsPromise.then (limits) ->
       $log.doLog = limits.doLog
]
