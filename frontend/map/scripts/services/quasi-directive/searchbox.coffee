app = require '../../app.coffee'
L = require 'leaflet'


app.service 'rmapsSearchboxService', ($log, leafletData) ->

  # need to have the id for the main map element (mapdiv)
  (mapdiv) ->
    leafletData.getMap(mapdiv)
    .then (map) ->

      # closure on the map for acquiring current bounds & zoom
      apiUrl = do (map) ->
        ->
          # calculate bounds and a basic scaling delta to expand around the viewbox
          bounds = map.getBounds()
          delta = 6/map.getZoom()
          left = bounds._southWest.lng+delta
          right = bounds._northEast.lng-delta
          top = bounds._northEast.lat-delta
          bottom = bounds._southWest.lat+delta

          # procure url;  openstreetmap query parameter urls: http://wiki.openstreetmap.org/wiki/Nominatim
          url = "//nominatim.openstreetmap.org/search?format=json&q={s}&viewbox=#{left},#{top},#{right},#{bottom}&bounded=1"
          url

      # marker reference
      searchMarker = new L.Icon
        iconUrl: 'assets/map_marker_out_red_64.png'

      # setup for search bar; available search options: https://github.com/stefanocudini/leaflet-search/blob/master/src/leaflet-search.js
      searchParams =
        wrapper: 'searchbox-container',
        text: 'Enter a city, address, neighbourhood, etc...',
        textErr: 'Processing... try being more specific.',
        url: apiUrl,
        markerIcon: searchMarker,
        jsonpParam: 'json_callback',
        propertyName: 'display_name',
        propertyLoc: ['lat','lon'],
        circleLocation: false,
        markerLocation: true,
        collapsed: false,
        autoType: false,
        tooltipLimit: 10,
        delayType: 0,
        minLength: 1,
        zoom:15

      # thing vomits when no imagePath defined
      L.Icon.Default.imagePath = 'assets/'
      map.addControl new L.Control.Search searchParams

    , (err) ->
      $log.error 'Error loading search bar:'
      $log.error err
