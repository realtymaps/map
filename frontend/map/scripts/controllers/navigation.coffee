app = require '../app.coffee'


###
  Parent controller over all the navigation dropdowns/popovers
###

module.exports = app.controller 'rmapsNavigationCtrl', ($scope, $log) ->

  $log = $log.spawn 'rmapsNavigationCtrl'
  $scope.isOpens = {}

