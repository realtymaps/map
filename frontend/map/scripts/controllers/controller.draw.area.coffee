app = require '../app.coffee'
mapId = 'mainMap'
color = 'red'

app.controller "rmapsDrawAreaCtrl", (
$scope,
$log,
$q,
$rootScope,
rmapsEventConstants,
rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory,
rmapsDrawCtrlFactory,
leafletData) ->

  $log = $log.spawn("map:rmapsDrawAreaCtrl")
  isReadyPromise = $q.defer()
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItemsAreas()
  .then (drawnItems) ->
    #filter drawItems which are only areas / frontend or backend
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    if !Object.keys(drawnItems._layers).length
      # There are zero areas, force propertiesInShapes to false
      $scope.Toggles.propertiesInShapes = false
      $rootScope.propertiesInShapes = false

    _handles = rmapsMapDrawHandlesFactory {
      mapId
      drawnShapesSvc
      drawnItems
      endDrawAction: () ->

      commonPostDrawActions: () ->
        $scope.$emit rmapsEventConstants.map.mainMap.redraw

      announceCb: () ->

      createPromise: (geoJson) ->
        #requires rmapsAreasModalCtrl to be in scope (parent)
        $scope.$emit rmapsEventConstants.map.mainMap.redraw
        $scope.create(geoJson)
    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory {
        mapId
        $scope
        handles
        drawnItems
        postDrawAction: ->
          $scope.$emit rmapsEventConstants.map.mainMap.redraw
        name: "area"
        itemsOptions:
          color: color
          fillColor: color
        drawOptions:
          control: (promisedControl) ->
            promisedControl.then (control) ->
              isReadyPromise.resolve(control)
          draw:
            polyline:
              shapeOptions: {color}
            polygon:
              shapeOptions: {color}
            rectangle:
              shapeOptions: {color}
            circle:
              shapeOptions: {color}
      }

    $scope.$watch 'Toggles.isAreaDraw', (newVal) ->
      if newVal
        _drawCtrlFactory(_handles)
        isReadyPromise.promise.then (control) ->
          control.enableHandle 'rectangle'
        return
      _drawCtrlFactory()

    $rootScope.$onRootScope rmapsEventConstants.areas.removeDrawItem, (event, model) ->
      leafletData.getMap(mapId)
      .then (map) ->
        toRemove = null
        keyToRemove = null

        for key, val of drawnItems._layers
          if val.model?.id == model.id
            toRemove = val
            keyToRemove = key
            break

        delete drawnItems._layers[keyToRemove]
        map.removeLayer toRemove
