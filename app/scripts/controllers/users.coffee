app = require '../app.coffee'

module.exports = app.controller 'UserCtrl'.ourNs(), ['$scope', 'Global'.ourNs(), ($scope, Global) ->
  $scope.global = Global
]
