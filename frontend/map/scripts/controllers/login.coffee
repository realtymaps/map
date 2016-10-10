app = require '../app.coffee'

module.exports = app.controller 'rmapsLoginCtrl', ($scope, rmapsLoginFactory) ->
  rmapsLoginFactory($scope)
