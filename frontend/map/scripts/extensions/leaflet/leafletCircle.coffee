L = require 'leaflet'
#hidden by Leaflet
_pointToGeoJSON = L.Circle::toGeoJSON
###
All of the below L.Circle extensions spawn from the fact that the GeoJSON spec does
not support circles. One should note that PostGIS does not either except in aproximations.

Therefore in doing GIS queries we will need to aproximate the circle as a polygon.

To be honest L.GeoJSON does a shoddy job at creating layers from existing geojson data
###


#extend to save off Circle Info
L.Circle::toGeoJSON = () ->
  feature = _pointToGeoJSON.apply(@)
  feature.properties = feature.properties or {}
  L.extend feature.properties,
    shape_extras:
      type: 'Circle'
      radius: @getRadius()
  feature

if L.Circle.createFromFeature
  throw new Error 'L.Circle.createFromFeature exists: prior to our definition. Library conflict!'

L.Circle.createFromFeature = (feature) ->
  if feature.properties?.shape_extras?.type != 'Circle'
    throw new Error 'Trying to create a Circle from a feature an invalid or non existent shapeType!'
  if !feature.properties?.shape_extras?.radius?
    throw new Error 'Trying to create a Circle with no radius!'
  new L.Circle new L.LatLng(feature.geometry.coordinates[1],feature.geometry.coordinates[0]),
    feature.properties.shape_extras.radius
