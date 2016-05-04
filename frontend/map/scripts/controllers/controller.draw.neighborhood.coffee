###globals _###
app = require '../app.coffee'
mapId = 'mainMap'
color = 'red'

app.controller "rmapsDrawNeighborhoodCtrl", (
$scope,
$log,
$rootScope,
rmapsEventConstants,
rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory,
rmapsDrawCtrlFactory,
leafletData) ->

  $log = $log.spawn("map:rmapsDrawNeighborhoodCtrl")

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItemsNeighborhoods()
  .then (drawnItems) ->
    #filter drawItems which are only neighborhoods / frontend or backend
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    if !Object.keys(drawnItems._layers).length
      # There are zero neighborhoods, force propertiesInShapes to false
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
        #requires rmapsNeighbourhoodsModalCtrl to be in scope (parent)
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
        name: "neighborhood"
        itemsOptions:
          color: color
          fillColor: color
        drawOptions:
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

    reLoadDarCtrlFactory = (newVal) ->
      if newVal
        return _drawCtrlFactory(_handles)
      _drawCtrlFactory()

    $scope.$watch 'Toggles.isNeighborhoodDraw', reLoadDarCtrlFactory
    $rootScope.$onRootScope rmapsEventConstants.neighbourhoods.removeDrawItem, (event, model) ->
      leafletData.getMap(mapId)
      .then (map) ->
        toRemove = null
        keyToRemove = null

        for key, val of drawnItems._layers
          if val.model.properties.id == model.properties.id
            toRemove = val
            keyToRemove = key
            break

        delete drawnItems._layers[keyToRemove]
        map.removeLayer toRemove
