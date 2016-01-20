app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectClientsCtrl', ($scope, $log) ->
  $log = $log.spawn("frontend:map:projectClients")
