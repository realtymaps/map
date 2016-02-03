app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectClientsCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectClients")
