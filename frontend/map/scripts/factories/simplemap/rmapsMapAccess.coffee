app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsMapAccess', (
  $log
  $rootScope

  leafletData

  rmapsBounds
  rmapsEventConstants
  rmapsGeometries
  rmapsMapScope
) ->

  #
  # Private Variables
  #
  $log = $log.spawn('rmapsMapAccess')

  #
  # Public API
  #
  class RmapsMapAccess
    isReady: false
    mapId: 'dashboardMap'
    map: null
    mapScope: rmapsMapScope,
    initPromise: null

    #
    # Constructor
    #
    constructor: () ->
      # This promise is resolved when Leaflet has finished setting up the Map
      @initPromise = leafletData.getMap(@mapId)
      @initPromise.then (map) =>
        @map = map
        @isReady = true

    # Take a list of properties and create the Map Scope markers to render
    addPropertyMarkers: (properties) ->
      if !properties?.length
        return

      @mapScope.markers = @mapScope.markers || {}
      angular.forEach properties, (property) =>
        if property.geom_point_json?.coordinates?
          @mapScope.markers[property.rm_property_id] = {
            lat: property.geom_point_json.coordinates[1],
            lng: property.geom_point_json.coordinates[0],
            draggable: false,
            focus: false,
            icon:
              type: 'div'
              className: 'project-dashboard-icon'
              html: '<span class="icon icon-neighbourhood"></span>'
          }

      return

    # Fit the map bounds to an array of properties
    fitToBounds: (properties) ->
      $log.debug("fitToBounds", properties)

      if !properties.length
        return

      if properties.length > 1
        bounds = rmapsBounds.boundsFromPropertyArray(properties)
        @mapScope.bounds = bounds
      else
        @mapScope.center = {
          lat: properties[0].geom_point_json.coordinates[1],
          lng: properties[0].geom_point_json.coordinates[0],
          zoom: 15
        }

      return

    # Add a marker click handler $scope.$on for the current map and ensure
    # that the marker click events are enabled on the Map Scope
    registerMarkerClick: ($scope, handler) ->
      @mapScope.enableMarkerEvent('click')

      event = "leafletDirectiveMarker.#{@mapId}.click"
      $log.debug "Register Marker Click #{event}"

      $scope.$on event, handler

    # Set the class of a property marker
    setPropertyClass: (propertyId, className, resetOtherMarkers = false) ->
      if resetOtherMarkers
        _.forOwn @mapScope.markers, (marker) ->
          marker.icon?.className = 'project-dashboard-icon'

      @mapScope.markers[propertyId]?.icon.className = className

  #
  # Service instance
  #
  service = new RmapsMapAccess()

  #
  # Private Implementation
  #
  clear = () ->
    service.map = null
    service.mapScope.clear()

  #
  # Handle Logout
  #
  $rootScope.$on rmapsEventConstants.principal.logout.success, () ->
    clear()

  #
  # Return the service instance
  #
  return service
