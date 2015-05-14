app = require '../app.coffee'
{Point} = require '../../../../common/utils/util.geometries.coffee'

app.service 'rmapsGoogleService'.ourNs(), ->
  GeoJsonTo: do ->
    _isCorrectType = (expected, geoJson) ->
      expected == geoJson.type

    _point = do ->
      type = 'Point'

      _toLatLon = (geoJson) ->
        return unless _isPoint(geoJson)
        new Point(geoJson.coordinates[1], geoJson.coordinates[0])

      #public
      toLatLon: _toLatLon
      toBounds:(geoJson) ->
        return unless _isCorrectType(type, geoJson)
        point = _toLatLon(geoJson)
        new L.latLngBounds(point,point)

    _multiPolygon = do ->
      type = 'MultiPolygon'
      toBounds:(geoJson) ->
        return unless _isCorrectType(type, geoJson)
        bounds = new L.latLngBounds([])
        geoJson.coordinates[0][0].forEach (coord) ->
          latLng = new L.LatLng(coord[1], coord[0])
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
      childModel = if model.model? then model.model else model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
