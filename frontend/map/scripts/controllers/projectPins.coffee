app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectPinsCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectPins")
