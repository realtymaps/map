app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserMLSCtrl', ($scope, $log) ->
  $log = $log.spawn("map:userMLS")
