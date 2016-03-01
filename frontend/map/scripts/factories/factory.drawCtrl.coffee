###globals _###
app = require '../app.coffee'

app.factory "rmapsDrawPostActionFactory", ($rootScope, rmapsEventConstants) ->
  ($scope) -> () ->
    if $scope.Toggles.propertiesInShapes
      $rootScope.$emit rmapsEventConstants.map.mainMap.reDraw

app.factory "rmapsDrawCtrlFactory", (
$rootScope, $log, rmapsNgLeafletEventGateService, toastr, rmapsMapDrawHandlesFactory,
leafletData, leafletDrawEvents, rmapsPrincipalService, rmapsEventConstants, rmapsDrawnUtilsService) ->
  {eachLayerModel} = rmapsDrawnUtilsService

  ({$scope, mapId, handles, drawnItems, postDrawAction, name, colorOptions}) ->

    if colorOptions
      drawnItems.getLayers().forEach (layer) ->
        _.extend layer.options, colorOptions

    $scope.draw =
      ready: false

    _hiddenDrawnItems = []

    # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
    $log = $log.spawn("map:rmapsDrawCtrlFactory:#{name}")


    if drawnItems?._layers?
      $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    mapPromise = leafletData.getMap(mapId)

    mapPromise.then (lMap) ->

      _destroy = () ->
        _hiddenDrawnItems = []

      _showHiddenLayers = () ->
        return unless _hiddenDrawnItems?._layers?

        $log.spawn("_hiddenDrawnItems").debug(Object.keys(_hiddenDrawnItems._layers).length)

        for layer in _hiddenDrawnItems
          drawnItems.addLayer(layer)
        _hiddenDrawnItems = []

      _hideNonNeighbourHoodLayers  = () ->
        eachLayerModel drawnItems, (model, layer) ->
          if !model?.properties?.neighbourhood_name?
            _hiddenDrawnItems.push layer
            drawnItems.removeLayer(layer)

      _.extend $scope.draw,
        mapPromise: mapPromise
        drawState: {}
        leafletDrawEvents: handles
        leafletDrawOptions:
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
        events:
          draw:
            enable: leafletDrawEvents.getAvailableEvents()

      #BEGIN SCOPE Extensions (better to be at bottom) if we ever start using this `this` instead of scope
      $rootScope.$on rmapsEventConstants.neighbourhoods.listToggled, (event, args...) ->
        [isOpen] = args
        if !isOpen
          _showHiddenLayers()
        else
          _hideNonNeighbourHoodLayers()
        postDrawAction()

      $scope.$watch 'Toggles.showNeighbourhoodTap', (newVal) ->
        eachLayerModel drawnItems, (model, layer) ->
          if newVal
            $log.debug "bound: #{rmapsEventConstants.neighbourhoods.createClick}"
            layer.on 'click', () ->
              $rootScope.$emit rmapsEventConstants.neighbourhoods.createClick, model, layer
            return
          layer.clearAllEventListeners()


      $scope.$on '$destroy', ->
        _destroy()
        $log.debug('destroyed')
      #END SCOPE Extensions

      $log.debug 'loaded'
      $scope.draw.ready = true
