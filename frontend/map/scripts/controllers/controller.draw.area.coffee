app = require '../app.coffee'


color = '#ffa500'
itemsOptions =
  color: color
  fillColor: color
  className: 'rmaps-area'

app.controller "rmapsDrawAreaCtrl", (
$scope
$log
$q
$rootScope
rmapsEventConstants
rmapsDrawnUtilsService
rmapsDrawCtrlFactory
rmapsMapTogglesFactory
rmapsFeatureGroupUtil
rmapsCurrentMapService
rmapsLayerUtilService
rmapsLeafletHelpers
) ->
  $scope.tacked = false

  obeyTacked = () ->
    if (!$scope.Toggles.isTacks.area && !$scope.Toggles.isStatsDraw) ||
    (!$scope.Toggles.isTacks.quickStats && $scope.Toggles.isStatsDraw)
      $scope.Toggles.isAreaDraw = false

  $log = $log.spawn("rmapsDrawAreaCtrl")

  isReadyPromise = $q.defer()

  mapId = rmapsCurrentMapService.mainMapId()
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItemsAreas()
  .then (drawnItems) ->

    $scope.drawn.items = drawnItems
    featureGroupUtil = new rmapsFeatureGroupUtil({featureGroup:drawnItems, ownerName: 'rmapsDrawAreaCtrl', className: 'rmaps-area'})

    $rootScope.$on rmapsEventConstants.areas.mouseOver, (event, model) ->
      $log.debug 'list mouseover'
      featureGroupUtil.onMouseOver(model)

    $rootScope.$on rmapsEventConstants.areas.mouseLeave, (event, model) ->
      $log.debug 'list mouseleave'
      featureGroupUtil.onMouseLeave(model)

    # filter drawItems which are only areas / frontend or backend
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    if !Object.keys(drawnItems._layers).length
      # There are zero areas, force propertiesInShapes to false
      $scope.Toggles.propertiesInShapes = false
      $rootScope.propertiesInShapes = false

    handleOptions = {
      createPromise: (layer) ->
        #requires rmapsAreasModalCtrl to be in scope (parent)
        geoJson = layer.toGeoJSON()
        p = if $scope.Toggles.isStatsDraw
          $scope.quickStats(geoJson)
          $scope.drawn.quickStats = layer
          $q.resolve()
        else
          $scope.create(geoJson)
          .then (result) ->
            $scope.$emit rmapsEventConstants.areas
            result

        p.then (result) ->
          obeyTacked()
          result


      deleteAction: (model) ->
        $scope.remove(model, {skipAreas: true})
        .then () ->
          if !Object.keys(drawnItems._layers).length
            rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes false

          #force refresh
          $scope.$emit rmapsEventConstants.areas

    }

    drawCtrl = rmapsDrawCtrlFactory {
      drawnShapesSvc
      featureGroupUtil
      handleOptions
      mapId
      $scope
      handleOptions
      drawnItems
      name: "area"
      itemsOptions
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
        drawCtrl.init(enable:true).then () ->
          isReadyPromise.promise.then (control) ->
            control.enableHandle(handle: 'rectangle')
      else
        drawCtrl.init(enable:false)

    $rootScope.$onRootScope rmapsEventConstants.areas.removeDrawItem, (event, geojsonModel) ->
      drawnItems.removeLayer featureGroupUtil.getLayer(geojsonModel)

    $rootScope.$onRootScope rmapsEventConstants.areas.addDrawItem, (event, geojsonModels) ->
      rmapsLeafletHelpers.geoJsonToFeatureGroup(geojsonModels, drawnItems, itemsOptions)
