app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsMapAccess', (
  $log
  $rootScope

  leafletData

  rmapsBounds
  rmapsEventConstants
  rmapsGeometries
  rmapsMapContext
) ->

  #
  # Private Variables
  #
  $log = $log.spawn('rmapsMapAccess')

  #
  # All Map Access instances
  #
  mapAccessCache = {}

  #
  # Map Access class implementation
  #
  class RmapsMapAccess
    isReady: false
    mapId: null
    map: null
    context: null,
    initPromise: null

    #
    # Constructor
    #
    constructor: (mapId) ->
      @mapId = mapId
      @context = rmapsMapContext.newMapContext()

      # This promise is resolved when Leaflet has finished setting up the Map
      @initPromise = leafletData.getMap(@mapId)
      @initPromise.then (map) =>
        @map = map
        @isReady = true

    # Take a list of properties and create the Map Scope markers to render
    addPropertyMarkers: (properties) ->
      if !properties?.length
        return

      @context.markers = @context.markers || {}
      angular.forEach properties, (property) =>
        if property.geom_point_json?.coordinates?
          @context.markers[property.rm_property_id] = {
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
        @context.bounds = bounds
      else
        @context.center = {
          lat: properties[0].geom_point_json.coordinates[1],
          lng: properties[0].geom_point_json.coordinates[0],
          zoom: 15
        }

      return

    # Add a marker click handler $scope.$on for the current map and ensure
    # that the marker click events are enabled on the Map Scope
    registerMarkerClick: ($scope, handler) ->
      @context.enableMarkerEvent('click')

      event = "leafletDirectiveMarker.#{@mapId}.click"
      $log.debug "Register Marker Click #{event}"

      $scope.$on event, handler

    # Set the class of a property marker
    setPropertyClass: (propertyId, className, resetOtherMarkers = false) ->
      if resetOtherMarkers
        _.forOwn @context.markers, (marker) ->
          marker.icon?.className = 'project-dashboard-icon'

      @context.markers[propertyId]?.icon.className = className

  #
  # Service instance API
  #
  service = {
    newMapAccess: (mapId) ->
      access = new RmapsMapAccess(mapId)
      mapAccessCache[mapId] = access

      return access

    findMapAccess: (mapId) ->
      return mapAccessCache[mapId]
  }

  #
  # Private Implementation
  #
  clear = () ->
    mapAccessCache = {}

  #
  # Handle Logout
  #
  $rootScope.$on rmapsEventConstants.principal.logout.success, () ->
    clear()

  #
  # Return the service instance
  #
  return service
