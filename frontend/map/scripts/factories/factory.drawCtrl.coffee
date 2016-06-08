###globals _###
app = require '../app.coffee'

app.factory "rmapsDrawCtrlFactory", (
$rootScope, $log, rmapsNgLeafletEventGateService, toastr, rmapsMapDrawHandlesFactory,
leafletData, leafletDrawEvents) ->

  ngLog = $log

  ({$scope, mapId, handles, drawnItems, postDrawAction, name, itemsOptions, drawOptions}) ->

    if itemsOptions?
      drawnItems.getLayers().forEach (layer) ->
        _.extend layer.options, itemsOptions

    $scope.draw =
      ready: false

    # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
    $log = ngLog.spawn("map:rmapsDrawCtrlFactory:#{name}")


    if drawnItems?._layers?
      ngLog.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    mapPromise = leafletData.getMap(mapId)

    mapPromise.then (lMap) ->

      _destroy = () ->

      _.extend $scope.draw,
        mapPromise: mapPromise
        drawState: {}
        leafletDrawEvents: handles
        leafletDrawOptions: _.merge(
          ngOptions:
            cssClass: 'btn btn-transparent nav-btn'
          position:"bottomright"
          draw:
            polyline:
              metric: false
            polygon:
              metric: false
              showArea: true
              drawError:
                color: '#b00b00' #TODO change colors to map theme
                timeout: 1000
              shapeOptions:
                color: '#bada55' #TODO change colors to map theme
            circle:
              showArea: true
              metric: false
              shapeOptions:
                color: '#662d91' #TODO change colors to map theme
            marker: false
          edit:
            featureGroup: drawnItems
            remove: true
        , drawOptions || {})
        events:
          draw:
            enable: leafletDrawEvents.getAvailableEvents()

      $scope.$on '$destroy', ->
        _destroy()
        $log.debug('destroyed')
      #END SCOPE Extensions

      $log.debug 'loaded'
      $scope.draw.ready = true
