###global _###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighbourhoodModal.jade'

app.controller 'rmapsNeighbourhoodsModalCtrl', ($rootScope, $scope, $modal,
rmapsProjectsService, rmapsMainOptions, rmapsEventConstants, rmapsDrawnUtilsService, rmapsMapTogglesFactory) ->

  _event = rmapsEventConstants.neighbourhoods

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

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
        _signalUpdate(drawnShapesSvc.create model)
        rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true

    update: (model) ->
      $scope.createModal(model).then (modalModel) ->
        _.merge(model, modalModel)
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      # $scope.neighbourhoods = _.omit $scope.neighbourhoods, model.properties.id
      delete model.properties.neighbourhood_name
      delete model.properties.neighbourhood_details
      _signalUpdate drawnShapesSvc.update model
      # .then () ->
      #   $scope.getAll()

.controller 'rmapsMapNeighbourhoodsCtrl', (
  $rootScope,
  $scope,
  $http,
  $log,
  rmapsDrawnUtilsService,
  rmapsEventConstants) ->

  ###
    Anything long term statewise goes here.
  ###
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $log = $log.spawn("map:neighbourhoods")

  $scope.getAll = (cache) ->
    drawnShapesSvc.getNeighborhoodsNormalized(cache)
    .then (data) ->
      $scope.neighbourhoods = _.indexBy data, 'properties.id'

  $scope.neighbourhoodListToggled = (isOpen) ->
    $scope.getAll(false)
    $rootScope.$emit rmapsEventConstants.neighbourhoods.dropdownToggled, isOpen

  $scope.getAll()
