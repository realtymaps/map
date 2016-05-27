app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectAreasCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectAreas")
