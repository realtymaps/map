_ = require 'lodash'
app = require '../app.coffee'

app.factory "rmapsDrawCtrlFactory", (
$rootScope
$log
rmapsNgLeafletEventGateService
toastr
leafletData
leafletDrawEvents
) ->

  hookItemsOptions = ({handles, itemsOptions, drawnItems}) ->
    if !itemsOptions
      return

    origDrawCreated = handles?["draw:created"]

    drawCreated = ({layer,layerType}) ->
      #extend new drawItems
      _.extend layer.options, itemsOptions
      #call original callback
      origDrawCreated?({layer,layerType})

    #override
    if handles
      handles["draw:created"] = drawCreated

    #extend original drawItems
    drawnItems.getLayers().forEach (layer) ->
      _.extend layer.options, itemsOptions

  ngLog = $log

  ({$scope, mapId, handles, drawnItems, name, itemsOptions, drawOptions}) ->

    hasBeenDisabled = false

    hookItemsOptions({handles, itemsOptions, drawnItems})

    $scope.$watch 'draw.enabled', (newVal, oldVal) ->
      return if !newVal?
      return if newVal == oldVal

      if newVal
        return if hasBeenDisabled
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
        hasBeenDisabled = true
      else
        return if !hasBeenDisabled
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
        hasBeenDisabled = false

    $scope.draw =
      ready: false

    # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
    $log = ngLog.spawn("map:rmapsDrawCtrlFactory:#{name}")


    if drawnItems?._layers?
      ngLog.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    mapPromise = leafletData.getMap(mapId)

    mapPromise.then () ->

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
            enable: leafletDrawEvents

      $scope.$on '$destroy', ->
        # need to disable events for shapes
        _destroy()
        $log.debug('destroyed')
      #END SCOPE Extensions

      $log.debug 'loaded'
      $scope.draw.ready = true
