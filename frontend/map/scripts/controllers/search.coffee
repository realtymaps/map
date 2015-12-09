app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
_ = require 'lodash'

module.exports = app.controller 'rmapsSearchCtrl', ($scope, $log, $rootScope, $location, $http, $timeout, rmapsPropertiesService, rmapsevents) ->
  $log = $log.spawn("map:search")

  $scope.searchScope = 'Properties'

  $scope.searchTooltip = "go for it"

  $scope.searchChanged = _.debounce () ->
    $log.debug "search: #{$scope.selectedFilters.ownerName}"
    # rmapsPropertiesService.getFilterResults 'search', undefined, '&owner=jesse'
    # .then (result) ->
    #   $log.debug result
  , 200

  $rootScope.$onRootScope rmapsevents.map.results, (evt, map) ->
    numResults = _.keys(map.markers.filterSummary).length
    $log.debug numResults
    if numResults == 0
      $scope.searchTooltip = "No results found, try removing some filters"
    else
      $scope.searchTooltip = "Found #{numResults} results"

  $scope.$watch 'markers.filterSummary', (newVal, oldVal) ->
    $log.debug newVal
