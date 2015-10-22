app = require '../app.coffee'
qs = require 'qs'


app.controller 'rmapsSatMapCtrl', ($log, $timeout, $rootScope, $http,rmapsBaseMap, leafletData, $scope, rmapsMapEventsHandlerService, rmapsMainOptions) ->
  _overlays = require '../utils/util.layers.overlay.coffee'
  limits = rmapsMainOptions.map
  _mapId = 'detailSatMap'

  @satMapFactory = new rmapsBaseMap($scope, limits.options, limits.redrawDebounceMilliSeconds, 'satMap', _mapId)
  # Don't show the main map controls here
  $scope.controls.custom = []
  rmapsMapEventsHandlerService(@satMapFactory, 'satMap')
  _.merge $scope,
    satMap:
      layers:
        overlays: _overlays($log)
      markers:
        filterSummary:{}
        backendPriceCluster:{}
        addresses:{}
      init: ->

  leafletData.getMap(_mapId).then (map) ->
    map.invalidateSize()
