app = require '../app.coffee'


###
  Parent controller over all the navigation dropdowns/popovers
###

module.exports = app.controller 'rmapsNavigationCtrl', ($scope, $log) ->

  $log = $log.spawn 'rmapsNavigationCtrl'
  $scope.isOpens =
    settings: false
    pinned: false
    favorites: false
    notes: false
    area: false
    mail: false
    sketch: false
    client: false
  $scope.togglePanel = (id) ->
    $log.debug("togglePanel: #{id} (now #{$scope.isOpens[id]})")
    $log.debug("prior state: #{JSON.stringify($scope.isOpens,null,2)}")
    if $scope.isOpens[id]
      # close all the others, and open this one
      for key of $scope.isOpens when key != id
        $scope.isOpens[key] = false
