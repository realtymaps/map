app = require '../app.coffee'
_ = require 'lodash'


module.exports = app.controller 'rmapsSearchCtrl', (
  $scope,
  $log,
  $rootScope,
  $timeout,
  $element,
  rmapsEventConstants,
  rmapsPropertiesService ) ->

  $log = $log.spawn("map:search")

  $scope.openSearchTools = false
  $scope.search = scope: 'Places'
  $scope.setSearchScope = (v) ->
    $scope.search.scope = v
  $scope.result = googlePlace: null

  $scope.clearSearch = () ->
    if $scope.search.scope == 'Places'
      $log.debug 'clearing places'
      $element.find('input')[0]?.value = ''
      $scope.result.googlePlace = null
    else if $scope.search.scope == 'Owners'
      $log.debug 'clearing owner'
      $rootScope.selectedFilters.ownerName = ''

  $scope.$watch 'search.scope', (newVal, oldVal) ->
    $log.debug oldVal, '->', newVal

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

      # Automatically pin the property, but only if it was a specific address and not e.g. a city
      if place_type.indexOf("address") != -1
        rmapsPropertiesService.getPropertyDetail(
          null
          ,geometry_center:
            type: 'Point'
            coordinates: [
              place.geometry.location.lng()
              place.geometry.location.lat()
            ]
          ,'filter'
        )
        .then ({mls, county}) ->
          if p = (mls?[0] || county?[0])
            if !rmapsPropertiesService.pins[p.rm_property_id]
              rmapsPropertiesService.pinUnpinProperty p

    else if _.isString place and !_.isString oldPlace
      # Clear address filter
      $rootScope.selectedFilters?.address = {}
