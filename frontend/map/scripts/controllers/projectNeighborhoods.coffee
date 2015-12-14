app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectNeighborhoodsCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectNeighborhoods")
