###globals _###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighbourhoodModal.jade'

app.controller 'rmapsNeighbourhoodsModalCtrl', (
$rootScope,
$scope,
$modal,
rmapsProjectsService,
rmapsMainOptions,
rmapsEventConstants,
rmapsDrawnUtilsService,
rmapsMapTogglesFactory,
rmapsLeafletHelpers) ->

  _event = rmapsEventConstants.neighbourhoods

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
    activeView: 'neighbourhoods'

    createModal: (neighbourhood = {}) ->
      modalInstance = $modal.open
        animation: rmapsMainOptions.modals.animationsEnabled
        template: template
        controller: 'rmapsModalInstanceCtrl'
        resolve: model: -> neighbourhood

      modalInstance.result

    create: (model) ->
      $scope.createModal().then (modalModel) ->
        _.merge(model, modalModel)
        if !model?.properties?.neighbourhood_name
          #makes the model a neighborhood with a defined empty string
          model.properties.neighbourhood_name = ''
        rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
        _signalUpdate(drawnShapesSvc.create model)

    update: (model) ->
      $scope.createModal(model).then (modalModel) ->
        _.merge(model, modalModel)
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      $scope.neighbourhoods = _.omit $scope.neighbourhoods, model.properties.id
      _signalUpdate drawnShapesSvc.delete model
      .then () ->
        $scope.$emit rmapsEventConstants.neighbourhoods.removeDrawItem, model
        $scope.$emit rmapsEventConstants.map.mainMap.redraw, false

.controller 'rmapsMapNeighbourhoodsCtrl', (
  $rootScope,
  $scope,
  $http,
  $log,
  rmapsDrawnUtilsService,
  rmapsEventConstants) ->

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()
  $log = $log.spawn("map:neighbourhoods")

  $scope.getAll = (cache) ->
    drawnShapesSvc.getNeighborhoodsNormalized(cache)
    .then (data) ->
      $scope.neighbourhoods = _.indexBy data, 'properties.id'

  $scope.neighbourhoodListToggled = (isOpen) ->
    $scope.getAll()
    $rootScope.$emit rmapsEventConstants.neighbourhoods.dropdownToggled, isOpen

  $scope.getAll()
