###global _###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighbourhood.jade'

app.controller 'rmapsNeighbourhoodsModalCtrl', ($rootScope, $scope, $modal,
rmapsProjectsService, rmapsMainOptions, rmapsEventConstants, rmapsDrawnUtilsService) ->

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

    update: (model) ->
      $scope.createModal(model).then (modalModel) ->
        _.merge(model, modalModel)
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      delete model.properties.neighbourhood_name
      delete model.properties.neighbourhood_details
      _signalUpdate drawnShapesSvc.update model

.controller 'rmapsMapNeighbourhoodsCtrl', ($rootScope, $scope, $http,
$log, rmapsDrawnUtilsService, rmapsEventConstants) ->

  ###
    Anything long term statewise goes here.
  ###
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $log = $log.spawn("map:neighbourhoods")

  getAll = (cache) ->
    drawnShapesSvc.getNeighborhoodsNormalized(cache).then (data) ->
      $log.debug "received data #{data.length} " if data?.length
      $scope.neighbourhoods = data

  $scope.neighbourhoodListToggled = (isOpen) ->
    getAll(false)
    $rootScope.$emit rmapsEventConstants.neighbourhoods.dropdownToggled, isOpen

  getAll()
