###globals _####
app = require '../app.coffee'
mapId = 'mainMap'

app.controller "rmapsMapDrawCtrl", (
$rootScope, $scope, $log, rmapsNgLeafletEventGateService, toastr, rmapsMapDrawHandlesFactory,
leafletData, leafletDrawEvents, rmapsPrincipalService, rmapsEventConstants, rmapsDrawnService) ->
  drawnShapesSvc = rmapsDrawnService.getDrawnShapesSvc()
  {getDrawnItems, eachLayerModel} =rmapsDrawnService

  _hiddenDrawnItems = []

  # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
  $log = $log.spawn("map:rmapsMapDrawCtrl")

  _toast = null

  getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    leafletData.getMap(mapId).then (lMap) ->
      _endDrawAction = () ->
        toastr.clear _toast
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)

      _destroy = () ->
        _hiddenDrawnItems = []

      _doToast = (msg, contextName) ->
        _toast = toastr.info msg, contextName,
          closeButton: true
          timeOut: 0
          onHidden: (hidden) ->
            _endDrawAction()

        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)

      _showHiddenLayers = () ->
        $log.spawn("_hiddenDrawnItems").debug(Object.keys(_hiddenDrawnItems._layers).length)
        for layer in _hiddenDrawnItems
          drawnItems.addLayer(layer)
        _hiddenDrawnItems = []

      _hideNonNeighbourHoodLayers  = () ->
        eachLayerModel drawnItems, (model, layer) ->
          if !model?.properties?.neighbourhood_name?
            _hiddenDrawnItems.push layer
            drawnItems.removeLayer(layer)

      _commonPostDrawActions = () ->
        if $scope.Toggles.propertiesInShapes
          $rootScope.$emit rmapsEventConstants.map.mainMap.reDraw

      _handles = rmapsMapDrawHandlesFactory {
        drawnShapesSvc
        drawnItems
        endDrawAction: _endDrawAction
        commonPostDrawActions: _commonPostDrawActions
        announceCb: _doToast
      }

      _.merge $scope,
        map:
          mapPromise:  leafletData.getMap('mainMap')
          drawState: {}
          leafletDrawEvents: _handles
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
        _commonPostDrawActions()

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
