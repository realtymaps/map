###global _:true, L:true ###
app = require '../app.coffee'
template = do require '../../html/views/templates/modals/neighborhood.jade'
mapId = 'mainMap'
originator = 'map'

app.controller 'rmapsNeighborhoodsModalCtrl', ($rootScope, $scope, $modal,
rmapsProjectsService, rmapsMainOptions, rmapsevents) ->

  _event = rmapsevents.neighborhoods
  drawnShapesSvc = rmapsProjectsService.drawnShapes($rootScope.principal.getCurrentProfile())

  _signalUpdate = (promise) ->
    return $rootScope.$emit _event unless promise
    promise.then ->
      $rootScope.$emit _event

  _.extend $scope,
    activeView: 'neighborhoods'

    createModal: (neighborhood = {}) ->
      modalInstance = $modal.open
        animation: rmapsMainOptions.modals.animationsEnabled
        template: template
        controller: 'rmapsModalInstanceCtrl'
        resolve: model: -> neighborhood

      modalInstance.result

    create: () ->
      $scope.createModal().then (model) ->
        _.extend model,
          project_id: $scope.selectedProject.project_id || undefined
        _signalUpdate drawnShapesSvc.update model

    update: (model) ->
      model = _.cloneDeep model
      $scope.createModal(model).then (model) ->
        _signalUpdate drawnShapesSvc.update model

    remove: (model) ->
      delete model.neighborhood_name
      delete model.neighborhood_details
      _signalUpdate drawnShapesSvc.update model

.controller 'rmapsMapNeighborhoodsTapCtrl', ($rootScope, $scope, rmapsMapEventsLinkerService, rmapsNgLeafletEventGate,
  leafletIterators, toastr, $log, rmapsevents) ->

  createFromModal = $scope.create
  ###
  This controller is meant to have a short life span. It is turned on to create or update neighborhoods.
  Once it goes out of context for that specific job it should be destroyed.
  ###

  linker = rmapsMapEventsLinkerService
  $log = $log.spawn("map:rmapsMapNeighborhoodsTapCtrl")

  $scope.$on '$destroy', ->
    $log.debug('destroyed')

  _destroy = () ->
    toastr.clear toast
    rmapsNgLeafletEventGate.enableMapCommonEvents(mapId)

    $scope.Toggles.showNeighborhoodTap = false

  toast = toastr.info 'Assign a shape (Circle, Polygon, or Square) by clicking one.', 'Create a Neighborhood',
    closeButton: true
    timeOut: 0
    onHidden: (hidden) ->
      _destroy()

  rmapsNgLeafletEventGate.disableMapCommonEvents(mapId)#safety precausion to not fire of unintended behavior

  $rootScope.$on rmapsevents.neighborhoods.createClick, (event, model, layer) ->
    createFromModal(model).finally ->
      _destroy()

.controller 'rmapsMapNeighborhoodsCtrl', ($rootScope, $scope, $http, $log, rmapsNotesService,
rmapsevents, rmapsLayerFormatters, leafletData, leafletIterators, rmapsMapEventsLinkerService) ->
  ###
    Anything long term statewise goes here.
  ###

  $log = $log.spawn("map:neighborhoods")


  $scope.$on '$destroy', ->
    if _.isArray markersUnSubs
      leafletIterators.each markersUnSubs, (unsub) ->
        unsub()

  getAll = () ->
    rmapsNotesService.getList().then (data) ->
      $log.debug "received data #{data.length} " if data?.length
      $scope.neighborhoods = data

  $scope.map.getAll = getAll

  $rootScope.$onRootScope rmapsevents.neighborhoods, ->
    getAll()

  getAll()
