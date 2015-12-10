app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
_ = require 'lodash'

module.exports = app.controller 'rmapsSearchCtrl', ($scope, $log, $rootScope, rmapsevents) ->
  $log = $log.spawn("map:search")

  $scope.searchScope = 'Properties'

  $scope.result = googlePlace: null

  $rootScope.$onRootScope rmapsevents.map.results, (evt, map) ->
    numResults = _.keys(map.markers.filterSummary).length

    if numResults == 0
      $scope.searchTooltip = "No results, try a different search or remove filters"
    else
      $scope.searchTooltip = "Found #{numResults} results"

  $scope.$watch 'result.googlePlace', (place, oldPlace) ->
    # $log.debug place

    if place?.geometry?.location?

      zoom = 17

      if place.types.indexOf "address" != -1
        zoom = 17
      else if place.types.indexOf "administrative_area_level_1" != -1
        zoom = 12
      else if place.types.indexOf "country" != -1
        zoom = 8

      $rootScope.$emit rmapsevents.map.center, coords:
        latitude: place.geometry.location.lat()
        longitude: place.geometry.location.lng() # reposition map event
        zoom: zoom

app.config ($tooltipProvider) ->
  $tooltipProvider.setTriggers
    'keyup': 'keydown'
