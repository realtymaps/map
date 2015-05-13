app = require '../app.coffee'
qs = require 'qs'

_overlays = require '../utils/util.layers.overlay.coffee'
_eventReg = require '../utils/util.events.coffee'

app.controller 'rmapsSatMapCtrl', ($log, $timeout, $rootScope, rmapsBaseMap, leafletData, $scope) ->

    limits = $scope.satMap.limits
    _mapId ='detailSatMap'

    @satMapFactory = new rmapsBaseMap($scope, limits.options, limits.redrawDebounceMilliSeconds, 'satMap', _mapId)
    _eventReg($timeout,$scope, @satMapFactory, limits, $log, 'satMap')
    _.merge $scope,
      satMap:
        layers:
          overlays: _overlays()
        markers:
          filterSummary:{}
          backendPriceCluster:{}
          addresses:{}
        init: ->

    leafletData.getMap(_mapId).then (map) =>
      map.invalidateSize()
