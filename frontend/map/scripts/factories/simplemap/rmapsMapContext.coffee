app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsMapContext', (
  $log

  rmapsGeometries
  rmapsUtilLayersBase
) ->
  $log = $log.spawn('RmapsMapContext')

  #
  # This class represents the Leaflet configuration values placed in the scope and access by the Leaflet directive
  #
  class RmapsMapContext
    #
    # Leaflet Scope Data
    #

    defaults: null

    bounds: null
    center: new rmapsGeometries.LeafletCenter(26.148111, -81.790809, 15)
    controls: null
    events: {}
    geojson: null
    layers:
      baselayers: rmapsUtilLayersBase
      overlays: {}

    markers: {}
    markersNested: true  # Leaflet directive seems to choke on this

    markersWatchOptions: null
    geojsonWatchOptions: null
    geojsonNested: true

    #
    # Constructor
    #
    contructor: () ->
      $log.debug('Construct Map Scope')

    #
    # Public functions
    #
    enableMarkerEvent: (eventName) ->
      if !@events.markers
        @events.markers = {
          enable: []
        }

      @events.markers.enable.push(eventName)

  #
  # Service instance
  #
  service = RmapsMapContext

  #
  # Return service
  #
  return service
