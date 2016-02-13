###global _###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighbourhood.jade'
mapId = 'mainMap'

#TODO: rename to rmapsProjectNeighbourhoods{Whatever}....

app.controller 'rmapsNeighbourhoodsModalCtrl', ($rootScope, $scope, $modal,
rmapsProjectsService, rmapsMainOptions, rmapsEventConstants) ->

  _event = rmapsEventConstants.neighbourhoods
  drawnShapesSvc = rmapsProjectsService.drawnShapes($rootScope.principal.getCurrentProfile())

  _signalUpdate = (promise) ->
    return $rootScope.$emit _event unless promise
    promise.then ->
      $rootScope.$emit _event

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
        _signalUpdate(drawnShapesSvc.update model)

    update: (model) ->
      $scope.createModal(model).then (modalModel) ->
        _.merge(model, modalModel)
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      delete model.properties.neighbourhood_name
      delete model.properties.neighbourhood_details
      _signalUpdate drawnShapesSvc.update model

.controller 'rmapsMapNeighbourhoodsTapCtrl', ($rootScope, $scope, rmapsMapEventsLinkerService, rmapsNgLeafletEventGateService,
  leafletIterators, toastr, $log, rmapsEventConstants) ->

  createFromModal = $scope.create
  ###
  This controller is meant to have a short life span. It is turned on to create or update neighbourhoods.
  Once it goes out of context for that specific job it should be destroyed.
  ###

  linker = rmapsMapEventsLinkerService
  $log = $log.spawn("map:rmapsMapNeighbourhoodsTapCtrl")

  $scope.$on '$destroy', ->
    $log.debug('destroyed')

  _destroy = () ->
    toastr.clear toast
    rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)

    $scope.Toggles.showNeighbourhoodTap = false

  toast = toastr.info 'Assign a shape (Circle, Polygon, or Square) by clicking one.', 'Create a Neighbourhood',
    closeButton: true
    timeOut: 0
    onHidden: (hidden) ->
      _destroy()

  rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)#safety precausion to not fire of unintended behavior

  $rootScope.$on rmapsEventConstants.neighbourhoods.createClick, (event, model, layer) ->
    createFromModal(model).finally ->
      _destroy()

.controller 'rmapsMapNeighbourhoodsCtrl', ($rootScope, $scope, $http, $log, rmapsProjectsService,
rmapsEventConstants, rmapsLayerFormattersService, leafletData, leafletIterators, rmapsMapEventsLinkerService) ->

  ###
    Anything long term statewise goes here.
  ###
  drawnShapesSvc = rmapsProjectsService.drawnShapes($rootScope.principal.getCurrentProfile())
  $log = $log.spawn("map:neighbourhoods")

  getAll = () ->
    drawnShapesSvc.getListNormalized().then (data) ->
      data = _.filter data, (d) ->
        d.properties.neighbourhood_name?
      $log.debug "received data #{data.length} " if data?.length
      $scope.neighbourhoods = data

  $rootScope.$onRootScope rmapsEventConstants.neighbourhoods, ->
    getAll()

  $scope.neighbourhoodListToggled = (isOpen) ->
    #originally was not going to put this into state but it is needed for service.properties
    $rootScope.neighbourhoodsListIsOpen = isOpen
    $rootScope.$emit rmapsEventConstants.neighbourhoods.listToggled, isOpen

  getAll()
