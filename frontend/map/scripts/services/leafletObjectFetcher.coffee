app = require '../app.coffee'
_ = require 'lodash'


app.factory 'rmapsLeafletObjectFetcherFactory', ($log, $q, leafletData) ->
  #elementId: div id
  (elementId) ->
    # ng-leaflets promise logic is kinda overkill,
    # the references are the same for the lifetime
    _lMarkers = null
    _lGeojsons = null

    leafletData.getMarkers(elementId)
    .then (lObjs) ->
      _lMarkers = lObjs

    leafletData.getGeoJSON(elementId)
    .then (lObjs) ->
      _lGeojsons = lObjs

    _getMarker = (rm_property_id, layerName = '') ->
      _lMarkers[layerName + rm_property_id] or _.get _lMarkers, [ layerName, rm_property_id ]

    _getPoly = (rm_property_id, layerName) ->
      return if !layerName or !_lGeojsons?[layerName]
      _.find _lGeojsons[layerName]._layers, (layer) ->
        layer.feature.rm_property_id == rm_property_id
    ###params:
      rm_property_id
      Markers layerName.rm_property_id
      GeoJSON .. finding out
    ###
    _get = (rm_property_id, layerName) ->
      marker = _getMarker(rm_property_id, layerName)
      geo = _getPoly(rm_property_id, layerName)

      #we could add a pram to do preference, but for now marker takes pref
      lObject = marker or geo
      type = if lObject == marker then 'marker' else 'geojson'

      lObject: lObject
      type: type

    @get = _get
    @
