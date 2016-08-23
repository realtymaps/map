###globals _,d3###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
template = do require '../../html/views/templates/modals/areaModal.jade'

app.controller 'rmapsAreasModalCtrl', (
$rootScope
$scope
$timeout
$modal
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
  $log = $log.spawn("map:areasModal")

  _event = rmapsEventConstants.areas

  removeNotificationQueue = []

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $scope.activeView = 'areas'

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

  $scope.createModal = (area = {}) ->
    modalInstance = $modal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: template
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> area

    modalInstance.result

  #create with no modal and default a name
  $scope.create = (model) ->
    model.properties.area_name = "Untitled Area"
    _signalUpdate(drawnShapesSvc.create model)
    .then (id) ->
      if !$scope.Toggles.propertiesInShapes
        rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
      else
        $scope.$emit rmapsEventConstants.map.mainMap.redraw
      id

  $scope.update = (model) ->
    $scope.createModal(model).then (modalModel) ->
      _.merge(model, modalModel)
      _signalUpdate drawnShapesSvc.update model

  $scope.remove = (model, {skipAreas, redraw = false} = {}) ->
    toCancel = removeNotificationQueue.shift()
    if toCancel?
      $timeout.cancel(toCancel)

    _.remove($scope.areas, model)

    if !skipAreas && !$scope.areas?.length
      rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes false

    _signalUpdate(drawnShapesSvc.delete(model))
    .then () ->
      removeNotificationQueue.push $timeout ->
        $scope.$emit rmapsEventConstants.areas.removeDrawItem, model
        $scope.$emit rmapsEventConstants.map.mainMap.redraw, redraw
      , 100

  $scope.sendMail = (model) ->
    $scope.newMail = {}
    modalInstance = $modal.open
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

  $scope.showStatistics = (model) ->
    $scope.areaToShow = model.properties

    $scope.centerOn(model)

    updateStatistics($scope.areaToShow.id)
    .then (stats) ->
      modalInstance = $modal.open
        animation: true
        scope: $scope
        template: require('../../html/views/templates/modals/statisticsArea.jade')()

  updateStatistics = (area_id) ->
    $log.debug "Querying for properties in area #{area_id}"
    $http.post(backendRoutes.properties.drawnShapes,
      {
        areaId: area_id
        state:
          filters: rmapsFilterManagerService.getFilters()
      }
    )
    .then ({data}) ->
      resultsArray = _.values(data).filter (r) -> r.price && r.sqft_finished
      $log.debug "calculating area #{area_id} stats"
      $scope.areaStatistics ?= {}
      $scope.areaStatistics[area_id] =
        count: resultsArray.length
        price_avg: d3.mean(resultsArray, (p) -> p.price)
        sqft_avg: d3.mean(resultsArray, (p) -> p.sqft_finished)
        price_sqft_avg: d3.mean(resultsArray, (p) -> p.price/p.sqft_finished)

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
