app = require '../app.coffee'
color = 'red'

app.controller "rmapsDrawAreaCtrl", (
$scope
$log
$q
$rootScope
rmapsEventConstants
rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory
rmapsMapIds
rmapsDrawCtrlFactory
rmapsMapTogglesFactory
) ->
  $log = $log.spawn("map:rmapsDrawAreaCtrl")
  isReadyPromise = $q.defer()

  mapId = rmapsMapIds.mainMap()
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItemsAreas()
  .then (drawnItems) ->
    # drawnItems.bringToBack() # Areas block parcel clicks, but this seems to hide areas altogether

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

      createPromise: (geoJson) ->
        #requires rmapsAreasModalCtrl to be in scope (parent)
        $scope.create(geoJson)
        .then (result) ->
          $scope.$emit rmapsEventConstants.areas
          result


      deleteAction: (model) ->
        $scope.remove(model, {skipAreas: true})
        .then () ->
          if !Object.keys(drawnItems._layers).length
            rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes false

          #force refresh
          $scope.$emit rmapsEventConstants.areas

    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory {
        mapId
        $scope
        handles
        drawnItems
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
          control.enableHandle(handle: 'rectangle')
        return
      _drawCtrlFactory()

    $rootScope.$onRootScope rmapsEventConstants.areas.removeDrawItem, (event, geojsonModel) ->
      toRemove = null

      for key, val of drawnItems._layers
        if val.model.properties?.id == geojsonModel.properties.id
          toRemove = val
          break

      drawnItems.removeLayer toRemove
