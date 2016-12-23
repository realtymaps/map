app = require '../app.coffee'
{Point} = require '../../../../common/utils/util.geometries.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
L = require 'leaflet'

app.service 'rmapsGoogleService', ($http, $log, $q) ->

  $log = $log.spawn 'rmapsGoogleService'

  apiKey = ''

  service =
    getAPI: () ->
      $http.get(backendRoutes.config.safeConfig, cache:true)
      .then ({data}) ->
        if data?.google
          return apiKey = "&key=#{data.google}"
      .then (key) ->
        if key
          $log.debug("Loading Google Maps API")
        else
          $log.warn("Loading Google Maps without an API key")

        deferred = $q.defer()

        if window.google?.maps
          deferred.resolve(window.google?.maps)
          return deferred.promise

        if !document.getElementById("rmaps-google-maps")
          fjs = document.getElementsByTagName("script")[0]

          window.rmapsGoogleMapsReady = (result) ->
            if window.google?.maps
              $log.debug 'Google Maps API Loaded', window.google.maps.version
              L.Google?.asyncInitialize() # Leaflet plugin deferred init
              deferred.resolve(window.google.maps)
            else
              $log.error 'Failed to load Google Maps API'
              deferred.reject()

          js = document.createElement("script")
          js.id = "rmaps-google-maps"
          js.src = "//maps.google.com/maps/api/js?v=3#{apiKey}&libraries=places&callback=rmapsGoogleMapsReady"
          fjs.parentNode.insertBefore(js, fjs)

        return deferred.promise

    GeoJsonTo: do ->

      _point = do ->
        type = 'Point'

        _toLatLon = (geoJson) ->
          return if type != geoJson.type
          new Point(geoJson.coordinates[1], geoJson.coordinates[0])

        #public
        toLatLon: _toLatLon
        toBounds:(geoJson) ->
          return if type != geoJson.type
          point = _toLatLon(geoJson)
          new L.latLngBounds(point,point)

      _multiPolygon = do ->
        toBounds:(geoJson) ->
          bounds = new L.latLngBounds([])
          if geoJson.type == 'MultiPolygon'
            polys = geoJson.coordinates[0][0]

          if geoJson.type == 'Point'
            polys = [geoJson.coordinates]

          polys.forEach (coord) ->
            latLng = new L.LatLng(coord[1], coord[0])
            bounds.extend latLng
          bounds

      _polygon =
        toBounds: (geoJson) ->
          bounds = new L.latLngBounds([])
          polys = geoJson.coordinates[0]
          polys.forEach (coord) ->
            latLng = new L.LatLng(coord[1], coord[0])
            bounds.extend latLng
          bounds


      Point: _point
      MultiPolygon: _multiPolygon
      Polygon: _polygon

    Map:
      isGPoly: (gObject) ->
        gObject?.setPath?

      isGMarker: (gObject) ->
        gObject?.getAnimation?

    UiMap:
      getCorrectModel: (model) ->
        if model.model?
          model.model
        else
          model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)

    StreetView: do ->
      getUrl: (geoObj, width, height, fov = '90', heading = '', pitch = '10', sensor = 'false') ->
        coords = geoObj?.geometry_center?.coordinates
        coords ?= geoObj?.geometry_center?.coordinates
        coords ?= geoObj?.coordinates

        if !coords
          return

        service.StreetView.getUrlForCoordinates(coords, width, height, fov, heading, pitch, sensor)

      getUrlForCoordinates: (lonLat, width, height, fov = '90', heading = '', pitch = '10', sensor = 'false') ->
        # https://developers.google.com/maps/documentation/javascript/reference#StreetViewPanorama
        # heading is better left as undefined as google figures out the best heading based on the lat lon target
        # we might want to consider going through the api which will gives us URL
        if heading
          heading = "&heading=#{heading}"

        unless lonLat
          return

        if !width && height
          width = height//0.75
        if width && !height
          height = width//1.33
        if !width || !height
          $log.warn 'size parameter required for streetview'
          return

        "//maps.googleapis.com/maps/api/streetview?size=#{width}x#{height}" +
          "&location=#{lonLat[1]},#{lonLat[0]}" +
          "&fov=#{fov}#{heading}&pitch=#{pitch}&sensor=#{sensor}#{apiKey}"

    Satellite: do ->
      getUrl: (geoObj, width, height, zoom = 18) ->
        coords = geoObj?.geometry_center?.coordinates
        coords ?= geoObj?.geometry_center?.coordinates
        coords ?= geoObj?.coordinates

        if !coords
          return

        if !width && height
          width = height//0.75
        if width && !height
          height = width//1.33
        if !width || !height
          $log.warn 'size parameter required for streetview'
          return

        "//maps.googleapis.com/maps/api/staticmap?center=#{coords[1]},#{coords[0]}" +
          "&zoom=#{zoom}&size=#{width}x#{height}&maptype=satellite&format=png#{apiKey}"

  return service
