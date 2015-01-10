#controller responsible for delegating map drawing (map-control) actions
#mapDrawingCtrl
app = require '../../app.coffee'
require '../../runners/run-templates.coffee'

module.exports =
  app.controller 'MapDebugCtrl'.ourNs(), [
    '$scope', '$rootScope', 'events'.ourNs(),
    ($scope, $rootScope, Events) ->
  ]