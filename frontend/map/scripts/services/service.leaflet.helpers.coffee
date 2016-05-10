###globals L###
app = require '../app.coffee'

app.service 'rmapsLeafletHelpers', () ->

  geoJsonToFeatureGroup = (geoJson) ->
    if !Array.isArray geoJson
      geoJson = [geoJson]

    drawnItems = new L.FeatureGroup()
    L.geoJson geoJson,
      onEachFeature: (feature, layer) ->
        if feature.properties?.shape_extras?.type = 'Circle'
          layer = L.Circle.createFromFeature feature
        layer.model = feature
        drawnItems.addLayer layer

    drawnItems

  {
    geoJsonToFeatureGroup
  }
