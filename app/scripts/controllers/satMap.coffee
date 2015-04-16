app = require '../app.coffee'
qs = require 'qs'


_overlays = require '../utils/util.layers.overlay.coffee'
_eventReg = require '../utils/util.events.coffee'
_baseLayer= require('../utils/util.layers.sat.map.base.coffee')

app.controller 'SatMapCtrl'.ourNs(), ['Logger'.ourNs(), '$timeout', '$rootScope',
  'BaseMap'.ourNs(), 'leafletData', '$scope'
  ($log, $timeout, $rootScope, BaseMap, leafletData, $scope) ->

    limits = $scope.satMap.limits
    _mapId ='detailSatMap'

    @satMapFactory = new BaseMap($scope, limits.options, limits.redrawDebounceMilliSeconds, 'satMap', _mapId,_baseLayer)
    _eventReg($timeout,$scope, @satMapFactory, limits, $log, 'satMap')
    _.merge $scope,
      satMap:
        layers:
          overlays: _overlays
        markers:
          filterSummary:{}
          backendPriceCluster:{}
          addresses:{}
        init: ->

    leafletData.getMap(_mapId).then (map) =>
      map.invalidateSize()

]
