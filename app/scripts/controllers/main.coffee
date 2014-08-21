app = require '../app.coffee'

module.exports = app.controller 'MainCtrl'.ourNs(), ['$scope', 'Global'.ourNs(), ($scope, Global) ->
  $scope.global = Global
]
