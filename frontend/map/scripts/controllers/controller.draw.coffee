###globals _####
app = require '../app.coffee'

mapId = 'mainMap'

#TODO: get colors from color palette

app.controller "rmapsMapDrawCtrl", (
$rootScope, $scope, $log, rmapsNgLeafletEventGateService, toastr,
leafletData, leafletDrawEvents, rmapsPrincipalService, rmapsEventConstants, rmapsDrawnService) ->
  drawnShapesSvc = rmapsDrawnService.getDrawnShapesSvc()
  _hiddenDrawnItems = []
  
  makeDrawKeys = (handles) ->
    _.mapKeys handles, (val, key) -> 'draw:' + key

  # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
  $log = $log.spawn("map:rmapsMapDrawCtrl")

  _toast = null
  rmapsDrawnService.getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    leafletData.getMap(mapId).then (lMap) ->

      lMap.addLayer(drawnItems)

      _endDrawAction = () ->
        toastr.clear _toast
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)

      _destroy = () ->
        _hiddenDrawnItems = []
        lMap.removeLayer(drawnItems)

      _doToast = (msg, contextName) ->
        _toast = toastr.info msg, contextName,
          closeButton: true
          timeOut: 0
          onHidden: (hidden) ->
            _endDrawAction()

        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)

      _getShapeModel = (layer) ->
        _.merge layer.model, layer.toGeoJSON()

      _eachLayerModel = (layersObj, cb) ->
        unless layersObj?
          $log.error("layersObj is undefined")
          return
        layersObj.getLayers().forEach (layer) ->
          cb(_getShapeModel(layer), layer)

      _showHiddenLayers = () ->
        $log.spawn("_hiddenDrawnItems").debug(Object.keys(_hiddenDrawnItems._layers).length)
        for layer in _hiddenDrawnItems
          drawnItems.addLayer(layer)
        _hiddenDrawnItems = []

      _hideNonNeighbourHoodLayers  = () ->
        _eachLayerModel drawnItems, (model, layer) ->
          if !model?.properties?.neighbourhood_name?
            _hiddenDrawnItems.push layer
            drawnItems.removeLayer(layer)

      _commonPostDrawActions = () ->
        if $scope.Toggles.propertiesInShapes
          $rootScope.$emit rmapsEventConstants.map.mainMap.reDraw


      _handles = makeDrawKeys
        created: ({layer,layerType}) ->
          drawnItems.addLayer(layer)
          drawnShapesSvc?.create(layer.toGeoJSON()).then ({data}) ->
            newId = data
            layer.model =
              properties:
                id: newId
            _commonPostDrawActions()
        edited: ({layers}) ->
          _eachLayerModel layers, (model) ->
            drawnShapesSvc?.update(model).then ->
              _commonPostDrawActions()
        deleted: ({layers}) ->
          _eachLayerModel layers, (model) ->
            drawnShapesSvc?.delete(model).then ->
              _commonPostDrawActions()
        drawstart: ({layerType}) ->
          _doToast('Draw on the map to query polygons and shapes','Draw')
        drawstop: ({layerType}) ->
          _endDrawAction()
        editstart: ({handler}) ->
          _doToast('Edit Drawing on the map to query polygons and shapes','Edit Drawing')
        editstop: ({handler}) ->
          _endDrawAction()
        deletestart: ({handler}) ->
          _doToast('Delete Drawing','Delete Drawing')
        deletestop: ({handler}) ->
          _endDrawAction()

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
        _eachLayerModel drawnItems, (model, layer) ->
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
