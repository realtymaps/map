app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsMapScope', (
  $log

  rmapsGeometries
  rmapsUtilLayersBase
) ->
  $log = $log.spawn('rmapsMapScope')

  #
  # Public API
  #
  class RmapsMapScope
    #
    # Leaflet Scope Data
    #

    defaults: null

    bounds: null
    center: new rmapsGeometries.LeafletCenter(26.148111, -81.790809, 15)
#    center: {
#      lat: 26.148111,
#      lng: -81.790809,
#      zoom: 15
#    }
    controls: null
    events: {}
    geojson: null
    layers:
      baselayers: rmapsUtilLayersBase

    markers: {}
    markersNested: false

    'markers-watch-options': null
    'geojson-watch-options': null
    'geojson-nested': true

    #
    # Constructor
    #
    contructor: () ->
      $log.debug('Construct Map Scope')

    #
    # Public functions
    #
    enableMarkerEvent: (eventName) ->
      @events.markers = @events.markers || {}
      @events.markers.enable = @events.markers.enable || []
      @events.markers.enable.push(eventName)

  #
  # Service instance
  #
  service = new RmapsMapScope()

  #
  # Private Implementation
  #
  clear = () ->


  #
  # Return service
  #
  return service
