L = require 'leaflet'
app = require '../app.coffee'

app.service 'rmapsLeafletHelpers', () ->

  geoJsonToFeatureGroup = (geoJson) ->
    if !Array.isArray geoJson
      geoJson = [geoJson]

    drawnItems = new L.FeatureGroup()
    L.geoJson geoJson,
      onEachFeature: (feature, layer) ->
        ['Circle', 'Marker'].forEach (name) ->
          if feature.properties?.shape_extras?.type == name
            layer = L[name].createFromFeature feature

        layer.model = feature
        drawnItems.addLayer layer

    drawnItems

  {
    geoJsonToFeatureGroup
  }
