app = require '../../app.coffee'

app.controller 'rmapsUsersStaffCtrl', ($scope, rmapsUsersGridFactory) ->
  rmapsUsersGridFactory($scope, is_staff: true)
