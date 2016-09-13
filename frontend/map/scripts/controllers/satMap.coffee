### globals _###
app = require '../app.coffee'


app.controller 'rmapsSatMapCtrl',
(
  $log,
  $timeout,
  $rootScope,
  $http,
  rmapsBaseMapFactory,
  leafletData,
  $scope,
  rmapsEventsHandlerService,
  rmapsMainOptions,
  rmapsOverlays
) ->

  rmapsOverlays.init()
  .then (overlays) ->
    _.merge $scope.satMap, layers: {overlays}

  limits = rmapsMainOptions.map

  @satMapFactory = new rmapsBaseMapFactory {
    scope: $scope
    options: limits.options
    redrawDebounceMilliSeconds: limits.redrawDebounceMilliSeconds
    mapPath: 'satMap'
    mapId: 'detailSatMap'
  }
  # Don't show the main map controls here
  $scope.controls.custom = []
  rmapsEventsHandlerService(@satMapFactory, 'satMap')
  _.merge $scope,
    satMap:
      markers:
        filterSummary:{}
        backendPriceCluster:{}
        addresses:{}
      init: ->

  leafletData.getMap(@mapId).then (map) ->
    map.invalidateSize()
