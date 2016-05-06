app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsMapContext', (
  $log

  rmapsGeometries
  rmapsUtilLayersBase
) ->
  $log = $log.spawn('RmapsMapContext')

  #
  # Public API
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

    markers: {}
    markersNested: false

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
      @events.markers = @events.markers || {}
      @events.markers.enable = @events.markers.enable || []
      @events.markers.enable.push(eventName)

  #
  # Service instance
  #
  service = {
    newMapContext: () ->
      new RmapsMapContext()
  }

  #
  # Return service
  #
  return service
