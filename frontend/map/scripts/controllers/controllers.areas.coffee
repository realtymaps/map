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

    #uses modal
    oldCreate: (model) ->
      $scope.createModal().then (modalModel) ->
        _.merge(model, modalModel)
        if !model?.area_name
          #makes the model an area with a defined empty string
          model.area_name = ''
        rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
        _signalUpdate(drawnShapesSvc.create model)

    #create with no modal and default a name
    create: (model) ->
      model.area_name = "Untitled Area"
      rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
      _signalUpdate(drawnShapesSvc.create model)

    update: (model) ->
      $scope.createModal(model).then (modalModel) ->
        _.merge(model, modalModel)
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      _.remove($scope.areas, model)
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

  getAll = (cache) ->
    drawnShapesSvc.getAreasNormalized(cache)
    .then (data) ->
      $scope.areas = data

  $scope.areaListToggled = (isOpen) ->
    getAll()
    $rootScope.$emit rmapsEventConstants.areas.dropdownToggled, isOpen

  #
  # Listen for updates to the list by create/remove
  #

  $scope.$onRootScope rmapsEventConstants.areas, () ->
    getAll()

  #
  # Load the area list
  #
  getAll()