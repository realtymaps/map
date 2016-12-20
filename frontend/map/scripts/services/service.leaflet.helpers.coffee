L = require 'leaflet'
app = require '../app.coffee'

app.service 'rmapsLeafletHelpers', () ->

  geoJsonToFeatureGroup = (geoJson, featureGroup, style = {}) ->
    if !Array.isArray geoJson
      geoJson = [geoJson]

    featureGroup ?= new L.FeatureGroup()
    L.geoJson geoJson,
      style: style
      onEachFeature: (feature, layer) ->
        ['Circle', 'Marker'].forEach (name) ->
          if feature.properties?.shape_extras?.type == name
            layer = L[name].createFromFeature feature

        layer.model = feature
        featureGroup.addLayer layer

    featureGroup

  {
    geoJsonToFeatureGroup
  }
