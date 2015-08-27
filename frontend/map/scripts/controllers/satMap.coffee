app = require '../app.coffee'
qs = require 'qs'

_eventReg = require '../utils/util.events.coffee'

app.controller 'rmapsSatMapCtrl', ($log, $timeout, $rootScope, $http,
  rmapsBaseMap, leafletData, $scope) ->

  _overlays = require '../utils/util.layers.overlay.coffee'

  limits = $scope.satMap.limits
  _mapId ='detailSatMap'

  @satMapFactory = new rmapsBaseMap($scope, limits.options, limits.redrawDebounceMilliSeconds, 'satMap', _mapId)
  _eventReg($timeout,$scope, @satMapFactory, limits, $log, 'satMap')
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
