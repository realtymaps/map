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
    # The Map Id used in the leaflet directive definition in template
    mapId: null

    # The Leaflet scope context variables provided to the Leaflet directive
    context: null,

    # The backing Leaflet map implementation itself
    map: null

    # Rmaps MarkerHelper marker sets being used by this map
    markers: {}

    # Is this Leaflet map ready to be used
    isReady: false

    # Leaflet initialization promise so that post-init actions can be taking by calling code
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

    # Add a set of markets to the map
    useMarkers: (markerHelper) ->
      @markers[markerHelper.markerType] = markerHelper
      markerHelper.context = @context
      @context.markers = markerHelper.markers

    # Add a marker click handler $scope.$on for the current map and ensure
    # that the marker click events are enabled on the Map Scope
    registerMarkerClick: ($scope, handler) ->
      @context.enableMarkerEvent('click')

      event = "leafletDirectiveMarker.#{@mapId}.click"
      $log.debug "Register Marker Click #{event}"

      $scope.$on event, handler


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
