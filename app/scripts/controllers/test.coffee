app = require '../app.coffee'

module.exports = app.controller 'TestCtrl'.ourNs(), [
  '$scope'
   ($scope) ->
     $scope.pageClass = 'page-test';
]