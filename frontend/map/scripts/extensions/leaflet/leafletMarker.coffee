L = require 'leaflet'
_pointToGeoJSON = L.Marker::toGeoJSON

L.Marker::toGeoJSON = () ->
  feature = _pointToGeoJSON.apply(@)
  feature.properties = feature.properties or {}

  L.extend feature.properties,
    shape_extras:
      type: 'Marker'
      options: @options

  feature

if L.Marker.createFromFeature
  throw new Error 'L.Marker.createFromFeature exists: prior to our definition. Library conflict!'

L.Marker.createFromFeature = (feature) ->

  options = feature.properties.shape_extras?.options || {}

  L.marker(new L.LatLng(
    feature.geometry.coordinates[1]
    ,feature.geometry.coordinates[0]
  ), {
    icon: L.divIcon(options.icon.options) || L.divIcon(
      className: 'leaflet-mouse-marker'
      iconAnchor: [20, 20]
      iconSize: [40, 40]
      ),
    opacity: options.opacity || 0,
    zIndexOffset: options.zIndexOffset || 2000
  })
