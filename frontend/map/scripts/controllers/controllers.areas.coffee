###globals _,d3###
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
  $log = $log.spawn("map:areasModal")

  _event = rmapsEventConstants.areas

  removeNotificationQueue = []

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $scope.activeView = 'areas'

  $scope.drawController = null

  $scope.drawn =
    items: null
    quickStats: null

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
    modalInstance = $uibModal.open
      animation: rmapsMainOptions.modals.animationsEnabled
      template: template
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> area

    modalInstance.result

  #create with no modal and default a name
  $scope.create = (model, layer) ->
    model.properties.area_name = "Untitled Area"
    _signalUpdate(drawnShapesSvc.create model)
    .then (id) ->
      if !$scope.Toggles.propertiesInShapes
        rmapsMapTogglesFactory.currentToggles?.setPropertiesInShapes true
      else
        $scope.$emit rmapsEventConstants.map.mainMap.redraw
      id

  $scope.quickStats = (model) ->
    $log.debug 'quick stats', model
    filters = rmapsFilterManagerService.getFilters()
    geometry = _.extend(model.geometry, model.properties?.shape_extras)
    body = { state: {filters}, geometry }
    $http.post(backendRoutes.properties.inGeometry, body, cache: false)
    .then ({data}) ->
      $log.debug data
      $scope.areaToShow = id: 0, area_name: 'Quick'
      updateStatistics(data, 0, true)

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

  $scope.showStatistics = (model) ->
    $scope.areaToShow = model.properties
    $scope.centerOn(model)

    $http.post(backendRoutes.properties.drawnShapes,
      {
        areaId: $scope.areaToShow.id
        state:
          filters: rmapsFilterManagerService.getFilters()
      }
    ).then ({data}) ->
      updateStatistics(data, $scope.areaToShow.id)

  updateStatistics = (data, area_id, showStatsSave) ->
    dataSet = _.values(data)

    stats = d3.nest()
    .key (d) ->
      d.status
    .rollup (status) ->
      valid_price = status.filter (p) -> p.price?
      valid_sqft = status.filter (p) -> p.sqft_finished?
      valid_price_sqft = status.filter (p) -> p.price? && p.sqft_finished?
      valid_dom = status.filter (p) -> p.days_on_market?
      valid_acres = status.filter (p) -> p.acres?
      count: status.length
      price_avg: d3.mean(valid_price, (p) -> p.price)
      price_n: valid_price.length
      sqft_avg: d3.mean(valid_sqft, (p) -> p.sqft_finished)
      sqft_n: valid_sqft.length
      price_sqft_avg: d3.mean(valid_price_sqft, (p) -> p.price/p.sqft_finished)
      price_sqft_n: valid_price_sqft.length
      days_on_market_avg: d3.mean(valid_dom, (p) -> p.days_on_market)
      days_on_market_n: valid_dom.length
      acres_avg: d3.mean(valid_acres, (p) -> p.acres)
      acres_n: valid_acres.length
    .entries(dataSet)

    stats = _.indexBy stats, 'key'
    $log.debug stats

    $scope.areaStatistics ?= {}
    $scope.areaStatistics[area_id] = stats

    $scope.showStatsSave = !!showStatsSave
    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/statisticsAreaStatus.jade')()

    modalInstance.result
    .then () ->
      $log.debug "saving layer", $scope.drawn.quickStats
      model = $scope.drawn.quickStats.toGeoJSON()
      model.properties.area_name = 'Untitle Area'
      drawnShapesSvc.create model
      .then (result) ->
        $log.debug result
        [id] = result.data
        $scope.drawn.quickStats.model =
          properties:
            id: id
    .catch () ->
      if $scope.drawn.quickStats
        $log.debug "deleting layer", $scope.drawn.quickStats
        $scope.drawn.items.removeLayer($scope.drawn.quickStats)

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
    getAll(false)
    $rootScope.$emit rmapsEventConstants.areas.dropdownToggled, isOpen

  #
  # Listen for updates to the list by create/remove
  #

  $scope.$onRootScope rmapsEventConstants.areas, () ->
    getAll(false)

  #
  # Load the area list
  #
  getAll()
