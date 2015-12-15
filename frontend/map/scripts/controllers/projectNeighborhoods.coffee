app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectNeighbourhoodsCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectNeighbourhoods")
