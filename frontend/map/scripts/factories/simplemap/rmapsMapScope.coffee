app = require '../../app.coffee'
Point = require('../../../../../common/utils/util.geometries.coffee').Point

module.exports = app

app.factory 'rmapsMapScope', (
  rmapsUtilLayersBase
) ->

  #
  # Public API
  #
  class RmapsMapScope
    #
    # Leaflet Scope Data
    #

    defaults: null

    bounds: null
#    center: null
    center: {
      lat: 26.148111,
      lng: -81.790809,
      zoom: 15
    }
    controls: null
    events: null
    geojson: null
    layers:
      baselayers: rmapsUtilLayersBase
    markers: {}

    'markers-nested': true
    'markers-watch-options': null
    'geojson-watch-options': null
    'geojson-nested': true

    #
    # Constructor
    #
    contructor: () ->

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
