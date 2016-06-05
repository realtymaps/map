app = require '../app.coffee'
qs = require 'qs'


app.controller 'rmapsSatMapCtrl',
(
  $log,
  $timeout,
  $rootScope,
  $http,
  rmapsBaseMapFactory,
  leafletData,
  $scope,
  rmapsMapEventsHandlerService,
  rmapsMainOptions,
  rmapsOverlays
) ->
  overlays = null
  rmapsOverlays
  .then (ovr) ->
    overlays = ovr

  limits = rmapsMainOptions.map
  _mapId = 'detailSatMap'

  @satMapFactory = new rmapsBaseMapFactory($scope, limits.options, limits.redrawDebounceMilliSeconds, 'satMap', _mapId)
  # Don't show the main map controls here
  $scope.controls.custom = []
  rmapsMapEventsHandlerService(@satMapFactory, 'satMap')
  _.merge $scope,
    satMap:
      layers: {overlays}
      markers:
        filterSummary:{}
        backendPriceCluster:{}
        addresses:{}
      init: ->

  leafletData.getMap(_mapId).then (map) ->
    map.invalidateSize()
