app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mapId = 'mainMap'
originator = 'map'

#TODO: get colors from color palette

app.controller "rmapsMapDrawCtrl", (
$rootScope, $scope, $log, rmapsMapEventsLinkerService, rmapsNgLeafletEventGateService, leafletIterators, toastr,
leafletData, leafletDrawEvents, rmapsPrincipalService, rmapsProjectsService, rmapsEventConstants) ->
  # shapesSvc = rmapsProfileDawnShapesService #will be using project serice or a drawService
  $log = $log.spawn("frontend:map:MapDrawCtrl")
  drawnShapesFact = rmapsProjectsService.drawnShapes
  drawnShapesSvc = null

  if profile = rmapsPrincipalService.getCurrentProfile()
    $log.debug('profile: project_id' + profile.project_id)
    drawnShapesSvc = drawnShapesFact(profile) unless drawnShapesSvc
    drawnShapesSvc.getList().then (drawnShapes) ->
      # # TODO: drawn shapes will get its own tables for GIS queries
      geoJson = L.geoJson drawnShapes,
        onEachFeature: (feature, layer) ->
          $log.debug feature
          if feature.properties?.shape_extras?.type = 'Circle'
            layer = L.Circle.createFromFeature feature
          layer.model = feature
          drawnItems.addLayer layer

  _toast = null
  drawnItems = new L.FeatureGroup()

  #call this on every shape change to save shapes

  _.merge $scope,
    map:
      drawState: {}
      leafletDrawOptions:
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

  leafletData.getMap(mapId).then (lMap) ->

    lMap.addLayer(drawnItems)

    _linker = rmapsMapEventsLinkerService
    _it = leafletIterators

    _endDrawAction = () ->
      toastr.clear _toast
      rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)

    _destroy = () ->
      _it.each _unsubscribes, (unsub) -> unsub()

    _doToast = (msg, contextName) ->
      _toast = toastr.info msg, contextName,
        closeButton: true
        timeOut: 0
        onHidden: (hidden) ->
          _endDrawAction()

      rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)

    _getShapeModel = (layer) ->
      model = _.merge layer.model, layer.toGeoJSON()

    _eachLayerModel = (layersObj, cb) ->
      unless layersObj?
        $log.error("layersObj is undefined")
        return
      layersObj.getLayers().forEach (layer) ->
        cb(_getShapeModel(layer), layer)

    _hiddenDrawnItems = []

    _showHiddenLayers = () ->
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
        $rootScope.$emit rmapsEventConstants.map.mainMap.redraw

    #see https://github.com/michaelguild13/Leaflet.draw#events
    _handle =
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

    _handle = _.mapKeys _handle, (val, key) -> 'draw:' + key
    _unsubscribes = _linker.hookDraw(mapId, _handle, originator)

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
