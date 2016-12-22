app = require '../app.coffee'

app.service 'rmapsNgLeafletHelpersService', (nemSimpleLogger) ->
  # $log = nemSimpleLogger.spawn("map:NgLeafletHelpers")
  @events =
    getMapIdEventStr: (mapId = '') ->
      if mapId
        mapId = mapId + '.'
      mapId

    markerEvents: ['click', 'dblclick', 'mousedown', 'mouseover', 'mouseout']
    #ng-leaflet inconsistency
    geojsonEvents: ['click', 'dblclick', 'mouseover', 'mouseout']

  @
