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
    groups: {}

    # Is this Leaflet map ready to be used
    isReady: false

    # Leaflet initialization promise so that post-init actions can be taking by calling code
    initPromise: null

    #
    # Constructor
    #
    constructor: (mapId) ->
      @mapId = mapId
      @context = new rmapsMapContext()

      # This promise is resolved when Leaflet has finished setting up the Map
      @initPromise = leafletData.getMap(@mapId)
      @initPromise.then (map) =>
        @map = map
        @isReady = true

    # Add a set of markets to the map
    addMarkerGroup: (markerGroup, visible = true) ->
      # Set the MapContext on the Marker Group
      markerGroup.init(@, @context)

      # Store the MarkerGroup by the layer name for access through the MapAccess instance
      @groups[markerGroup.layerName] = markerGroup

      # Add the group overlay to the Map Context
      @context.layers.overlays[markerGroup.layerName] = {
        name: markerGroup.layerName
        type: 'group'
        visible: visible
      }

      # Add the group markers to the Map Context
      @context.markers[markerGroup.layerName] = markerGroup.markers


  #
  # Service instance API
  #
  service = {
    newMapAccess: (mapId) ->
      access = new RmapsMapAccess(mapId)
      return access
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
