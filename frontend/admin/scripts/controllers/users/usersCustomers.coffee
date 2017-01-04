app = require '../../app.coffee'

app.controller 'rmapsUsersCustomersCtrl', ($scope, rmapsUsersGridFactory) ->
  rmapsUsersGridFactory($scope)
