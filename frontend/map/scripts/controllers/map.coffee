###globals _, google###
app = require '../app.coffee'
require '../factories/map.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
{Point, NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
{uiProfile} = require('../../../../common/utils/util.profile.coffee')

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined


module.exports = app

app.controller 'rmapsMapCtrl', (
  $http,
  $location,
  $log,
  $modal,
  $q,
  $rootScope,
  $scope,
  $state,
  $timeout,
  $window,

  rmapsDrawnUtilsService,
  rmapsEventConstants,
  rmapsLeafletHelpers,
  rmapsMainOptions,
  rmapsMapFactory,
  rmapsParcelEnums,
  rmapsProfilesService
  rmapsProjectsService,
  rmapsPropertiesService,
  rmapsSearchboxService,

  currentIdentity,
  currentProfile
) ->

  $log = $log.spawn("map:controller")
  $log.debug("Map Controller init")

  $scope.satMap = {}#accessor to satMap so that satMap is in the scope chain for resultsFormatter

  $scope.init = (pageClass) ->
    $scope.pageClass = pageClass
  #end inits

  rmapsSearchboxService('mainMap')

  #
  # Create the Map Factory
  #
  if !map? or !$scope.map?
    map = new rmapsMapFactory($scope)

  #
  # Utility functions to load a new Project and optional Property from the Map based selection tool
  #

  # Load Property
  $scope.loadProperty = (project) ->
    selectedResultId = $state.params.property_id or project.map_results?.selectedResultId

    if selectedResultId?.match(/\w+_\w*_\w+/) and map?
      $log.debug 'attempting to reinstate selectedResult', selectedResultId

      $location.search 'property_id', selectedResultId

      rmapsPropertiesService.getPropertyDetail(
        map.scope.refreshState(map_results: selectedResultId: selectedResultId),
        rm_property_id: selectedResultId, 'all'
      ).then (result) ->
        return if _.isString result #not sure how this was happening but if we get it bail (should be an object)
        $timeout () ->
          map.scope.selectedResult = _.extend {}, map.scope.selectedResult, result
        , 50
        resultCenter = new Point(result.coordinates[1],result.coordinates[0])
        resultCenter.zoom = 18
        map.scope.map.center = resultCenter
      .catch () ->
        $location.search 'property_id', undefined
        newState = map.scope.refreshState(map_results: selectedResultId: undefined)
        rmapsPropertiesService.updateMapState newState
    else
      $location.search 'property_id', undefined

  #
  # Center on an area if requested
  #
  checkCenterOnArea = () ->
    areaId = $state.params.area_id || $location.search().area_id

    if areaId
      #zoom to bounds on shapes
      #handle polygons, circles, and points
      drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()
      drawnShapesSvc.getAreaByIdNormalized(rmapsProfilesService.currentProfile.project_id, areaId)
      .then (area) ->
        $timeout(() ->
          featureGroup = rmapsLeafletHelpers.geoJsonToFeatureGroup(area)
          feature = featureGroup._layers[Object.keys(featureGroup._layers)[0]]
          bounds = feature.getBounds()

          $rootScope.$emit rmapsEventConstants.map.fitBoundsProperty, bounds
        , 10)


  #
  # Set $scope variables for the Project selector tool
  #
  setScopeVariables = () ->
    $scope.loadProperty rmapsProfilesService.currentProfile
    checkCenterOnArea()

  #
  # Watch for changes to the current profile. This is necessary since the map state is sticky
  #
  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, identity) ->
    setScopeVariables()

  setScopeVariables()

# fix google map views after changing back to map state
app.run ($rootScope, $timeout) ->
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    # if we're not entering the map state, or if we're already on the map state, don't do anything
    if toState.url != frontendRoutes.map || fromState.url == frontendRoutes.map
      return

    return unless map?.scope.controls?.streetView?
    $timeout () ->
      # main map
      map?.scope.control.refresh?()
      # street view map -- TODO: this doesn't work for street view, not sure why
      gStrMap = map?.scope.controls.streetView.getGObject?()
      if gStrMap?
        google.maps.event.trigger(gStrMap, 'resize')
    , 500
