app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsMapAccess', (
  $log
  $rootScope

  leafletBoundsHelpers
  leafletData

  rmapsEventConstants
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
    mapScope: rmapsMapScope

    #
    # Constructor
    #
    constructor: () ->
      # This promise is resolved when Leaflet has finished setting up the Map
      leafletData.getMap(@mapId).then (map) =>
        @map = map
        @isReady = true

    fitToBounds: (properties) ->
      $log.debug("fitToBounds", properties)

      if !properties.length
        return

      if properties.length > 1
        coordinates = []
        angular.forEach properties, (property) ->
          if property.geom_point_json?.coordinates?
            coordinates.push(property.geom_point_json.coordinates.reverse())

        bounds = leafletBoundsHelpers.createBoundsFromArray(coordinates)
        @mapScope.bounds = bounds
      else
        @mapScope.center = {
          lat: properties[0].geom_point_json.coordinates[1],
          lng: properties[0].geom_point_json.coordinates[0],
          zoom: 15
        }

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
