app = require '../app.coffee'

app.factory 'rmapsLeafletObjectFetcher', [
  'rmapsLogger', '$q', 'leafletData', ($log, $q, leafletData) ->
    ###params:
      elementId: div id
      lModelId: usually rm_propertyid (However)
      Markers layerName.rm_propertyid
      GeoJSON .. finding out
    ###
    get: (elementId, lModelId) ->
      _lMarkers = null
      _lGeojsons = null
      d = $q.defer()

      promises = [
        leafletData.getMarkers(elementId)
        .then (lObjs) ->
          _lMarkers = lObjs
        ,
        leafletData.getGeoJSON(elementId)
        .then (lObjs) ->
          _lGeojsons = lObjs
      ]
      $q.all(promises).then ->
        marker = _lMarkers[lModelId]
        geo = _lGeojsons[lModelId]

        #we could add a pram to do preference, but for now marker takes pref
        lObject = marker or geo
        type = if lObject == marker then 'marker' else 'geojson'
        payload =
          lObject: lObject
          type: type
        d.resolve(payload)

      d.promise
]
