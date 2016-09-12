### globals _ ###
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
    # Non-Leaflet data
    #
    mapId: null

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
      baselayers: {}
      overlays: {}

    markers: {}
    markersNested: true  # Leaflet directive seems to choke on this

    markersWatchOptions: null
    geojsonWatchOptions: null
    geojsonNested: true

    #
    # Constructor
    #
    constructor: (mapId) ->
      @mapId = mapId
      @baseLayers

      rmapsUtilLayersBase.init()
      .then (data) =>
        _.extend(@layers.baselayers, data)


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
