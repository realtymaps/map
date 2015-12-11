app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
_ = require 'lodash'

module.exports = app.controller 'rmapsSearchCtrl', ($scope, $log, $rootScope, $location, $http, $timeout, rmapsPropertiesService, rmapsevents) ->
  $log = $log.spawn("map:search")

  $scope.searchScope = 'Properties'

  $rootScope.$onRootScope rmapsevents.map.results, (evt, map) ->
    numResults = _.keys(map.markers.filterSummary).length
    $log.debug numResults
    if numResults == 0
      $scope.searchTooltip = "No results, try a different search or remove filters"
    else
      $scope.searchTooltip = "Found #{numResults} results"

app.config ($tooltipProvider) ->
  $tooltipProvider.setTriggers
    'keyup': 'keydown'
