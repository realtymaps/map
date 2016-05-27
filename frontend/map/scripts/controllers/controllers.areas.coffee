###globals _###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/areaModal.jade'

app.controller 'rmapsAreasModalCtrl', (
$rootScope,
$scope,
$modal,
rmapsProjectsService,
rmapsMainOptions,
rmapsEventConstants,
rmapsDrawnUtilsService,
rmapsMapTogglesFactory,
rmapsLeafletHelpers) ->

  _event = rmapsEventConstants.areas

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $scope.centerOn = (model) ->
    #zoom to bounds on shapes
    #handle polygons, circles, and points
    featureGroup = rmapsLeafletHelpers.geoJsonToFeatureGroup(model)
    feature = featureGroup._layers[Object.keys(featureGroup._layers)[0]]
    $rootScope.$emit rmapsEventConstants.map.fitBoundsProperty, feature.getBounds()

  _signalUpdate = (promise) ->
    return $rootScope.$emit _event unless promise
    promise.then (data) ->
      $rootScope.$emit _event
      data

  _.extend $scope,
    activeView: 'areas'

    createModal: (area = {}) ->
      modalInstance = $modal.open
        animation: rmapsMainOptions.modals.animationsEnabled
        template: template
        controller: 'rmapsModalInstanceCtrl'
        resolve: model: -> area

      modalInstance.result

    create: (model) ->
      $scope.createModal().then (modalModel) ->
        _.merge(model, modalModel)
        if !model?.properties?.neighbourhood_name
          #makes the model an area with a defined empty string
          model.properties.neighbourhood_name = ''
        rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
        _signalUpdate(drawnShapesSvc.create model)

    update: (model) ->
      $scope.createModal(model).then (modalModel) ->
        _.merge(model, modalModel)
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      $scope.areas = _.omit $scope.areas, model.properties.id
      _signalUpdate drawnShapesSvc.delete model
      .then () ->
        $scope.$emit rmapsEventConstants.areas.removeDrawItem, model
        $scope.$emit rmapsEventConstants.map.mainMap.redraw, false

.controller 'rmapsMapAreasCtrl', (
  $rootScope,
  $scope,
  $http,
  $log,
  rmapsDrawnUtilsService,
  rmapsEventConstants) ->

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()
  $log = $log.spawn("map:areas")

  $scope.getAll = (cache) ->
    drawnShapesSvc.getAreasNormalized(cache)
    .then (data) ->
      $scope.areas = _.indexBy data, 'properties.id'

  $scope.areaListToggled = (isOpen) ->
    $scope.getAll()
    $rootScope.$emit rmapsEventConstants.areas.dropdownToggled, isOpen

  $scope.getAll()
