app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
_ = require 'lodash'

module.exports = app.controller 'rmapsSearchCtrl', ($scope, $log, $rootScope, $timeout, rmapsEventConstants) ->
  $log = $log.spawn("map:search")

  $scope.openSearchTools = false
  $scope.searchScope = 'Places'

  $scope.result = googlePlace: null

  $rootScope.$onRootScope rmapsEventConstants.map.results, (evt, map) ->
    numResults = _.keys(map.markers.filterSummary).length

    if numResults == 0
      $scope.searchTooltip = "No results, try a different search or remove filters"
    else
      $scope.searchTooltip = "Found #{numResults} results"

  $scope.$watch 'result.googlePlace', (place, oldPlace) ->
    # $log.debug place

    if place?.geometry?.location?

      # Reposition the map on the selected place and set an appropriate zoom level
      zoom = 16

      place_type = place.types.join(' ')

      $log.debug place_type

      if place_type.indexOf("address") != -1 # property
        zoom = 20
      else if place_type.indexOf("locality") != -1 # city
        zoom = 12
      else if place_type.indexOf("administrative_area_level_1") != -1 # state
        zoom = 7
      else if place_type.indexOf("country") != -1 # country
        zoom = 5

      $rootScope.$emit rmapsEventConstants.map.center,
        coords:
          latitude: place.geometry.location.lat()
          longitude: place.geometry.location.lng()
        zoom: zoom
        showCenter: true

      # Add address to property filters -- if available this property should be returned independent of other filters
      $timeout () ->
        $rootScope.selectedFilters?.address =
          street_address_num: (_.find place.address_components, (c) -> c.types.indexOf('street_number') != -1)?.short_name ? ""
          street_address_name: (_.find place.address_components, (c) -> c.types.indexOf('route') != -1)?.short_name ? ""
          city: (_.find place.address_components, (c) -> c.types.indexOf('locality') != -1)?.short_name ? ""
          state: (_.find place.address_components, (c) -> c.types.indexOf('administrative_area_level_1') != -1)?.short_name ? ""
          zip: (_.find place.address_components, (c) -> c.types.indexOf("postal_code") != -1)?.short_name ? ""

    else if _.isString place and !_.isString oldPlace
      # Clear address filter
      $rootScope.selectedFilters?.address = {}
