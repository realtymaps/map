app = require '../app.coffee'

app.service 'GoogleService'.ourNs(), ->
  GeoJsonTo: do ->
    _isCorrectType = (expected, geoJson) ->
      expected == geoJson.type

    _point = do ->
      type = 'Point'

      _toLatLon = (geoJson) ->
        return unless _isPoint(geoJson)
        new google.maps.LatLng(geoJson.coordinates[1], geoJson.coordinates[0])

      #public
      toLatLon: _toLatLon
      toBounds:(geoJson) ->
        return unless _isCorrectType(type, geoJson)
        point = _toLatLon(geoJson)
        new google.maps.LatLngBounds(point,point)

    _multiPolygon = do ->
      type = 'MultiPolygon'
      toBounds:(geoJson) ->
        return unless _isCorrectType(type, geoJson)
        bounds = new google.maps.LatLngBounds()
        geoJson.coordinates[0][0].forEach (coord) ->
          latLng = new google.maps.LatLng(coord[1], coord[0])
          bounds.extend latLng
        bounds

    Point: _point
    MultiPolygon: _multiPolygon

  Map:
    isGPoly: (gObject) ->
      gObject?.setPath?

    isGMarker: (gObject) ->
      gObject?.getAnimation?

  UiMap:
    getCorrectModel: (model) ->
      childModel = if model.model? then model else model: model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
