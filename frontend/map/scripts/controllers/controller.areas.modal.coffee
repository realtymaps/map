###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
template = do require '../../html/views/templates/modals/areaModal.jade'

app.controller 'rmapsAreasModalCtrl', (
$rootScope
$scope
$timeout
$uibModal
$http
$log
$state
rmapsProjectsService
rmapsMainOptions
rmapsEventConstants
rmapsDrawnUtilsService
rmapsMapTogglesFactory
rmapsFilterManagerService
rmapsLeafletHelpers) ->
  $log = $log.spawn("rmapsAreasModalCtrl")

  _event = rmapsEventConstants.areas

  removeNotificationQueue = []

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $scope.drawnShapesSvc = drawnShapesSvc

  $scope.activeView = 'areas'

  $scope.drawController = null

  $scope.drawn = _.extend $scope.drawn || {},
    items: null

  $scope.checkToggleInShapes = () ->
    if !$scope.Toggles.propertiesInShapes
      rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
    else
      $scope.$emit rmapsEventConstants.map.mainMap.redraw

  $scope.centerOn = (model) ->
    #zoom to bounds on shapes
    #handle polygons, circles, and points
    featureGroup = rmapsLeafletHelpers.geoJsonToFeatureGroup(model)
    feature = featureGroup._layers[Object.keys(featureGroup._layers)[0]]
    $rootScope.$emit rmapsEventConstants.map.fitBoundsProperty, feature.getBounds()

  $scope.signalUpdate = signalUpdate = (promise) ->
    return $rootScope.$emit _event unless promise
    promise.then (data) ->
      $rootScope.$emit _event
      data

  $scope.createModal = (area = {}) ->
    modalInstance = $uibModal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: template
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> area

    modalInstance.result

  #create with no modal and default a name
  ### eslint-disable###
  $scope.create = (model, layer) ->
    ### eslint-enable###
    model.properties.area_name = "Untitled Area"
    signalUpdate(drawnShapesSvc.create model)
    .then (id) ->
      $scope.checkToggleInShapes()
      id

  $scope.update = (model) ->
    $scope.createModal(model).then (modalModel) ->
      _.merge(model, modalModel)
      signalUpdate drawnShapesSvc.update model

  $scope.remove = (model, {skipAreas, redraw = false} = {}) ->
    toCancel = removeNotificationQueue.shift()
    if toCancel?
      $timeout.cancel(toCancel)

    _.remove($scope.areas, model)

    if !skipAreas && !$scope.areas?.length
      rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes false

    signalUpdate(drawnShapesSvc.delete(model))
    .then () ->
      removeNotificationQueue.push $timeout ->
        $scope.$emit rmapsEventConstants.areas.removeDrawItem, model
        $scope.$emit rmapsEventConstants.map.mainMap.redraw, redraw
      , 100

  $scope.onMouseOver = (model) ->
    $scope.$emit rmapsEventConstants.areas.mouseOver, model

  $scope.onMouseLeave = (model) ->
    $scope.$emit rmapsEventConstants.areas.mouseLeave, model

  $scope.sendMail = (model) ->
    $scope.newMail = {}
    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/mailArea.jade')()

    $scope.modalOk = ->
      filters = {}
      if $scope.newMail.filterProperties == 'true'
        filters = rmapsFilterManagerService.getFilters()
      $scope.modalBusy = $http.post(backendRoutes.properties.inArea, {
        areaId: model.properties.id
        state: {filters}
      }, cache: false)
      .then ({data}) ->
        modalInstance.dismiss('done')
        $state.go 'recipientInfo', {property_ids: data}, {reload: true}
