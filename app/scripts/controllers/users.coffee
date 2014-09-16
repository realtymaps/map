app = require '../app.coffee'

module.exports = app.controller 'UserCtrl'.ourNs(), [
  '$scope', 'User'.ourNs(), ($scope, User) ->
    $scope.global = Global
]
