_ = require 'lodash'
app = require '../app.coffee'
{LeafletCenter} = require('../../../../common/utils/util.geometries.coffee')

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###

module.exports = app

app.controller 'rmapsMapCtrl', (
  $http,
  $location,
  $log,
  $uibModal,
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
  rmapsClientEntryService,
  rmapsBounds
) ->
  $log = $log.spawn("map:controller")

  $scope.$on '$destroy', ->
    $log.debug -> "mapId: #{$scope.mapId} destroyed"

  $scope.satMap = {}#accessor to satMap so that satMap is in the scope chain for resultsFormatter

  $scope.init = (pageClass) ->
    $scope.pageClass = pageClass
  #end inits


  #
  # Create the Map Factory
  #
  map = new rmapsMapFactory($scope)
  $scope.mapId = mapId = map.mapId
  rmapsSearchboxService(mapId)

  #
  # Utility functions to load a new Project and optional Property from the Map based selection tool
  #

  # Load Property
  $scope.loadProperty = (project) ->
    if !project
      return
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
        resultCenter = new LeafletCenter(result.coordinates[1],result.coordinates[0], 18)
        resultCenter.docWhere = 'rmapsMapCtrl.scope.loadProperty'
        map.scope.map.center = resultCenter
      .catch () ->
        $location.search 'property_id', undefined
        newState = map.scope.refreshState(map_results: selectedResultId: undefined)
        rmapsPropertiesService.updateMapState newState
    else
      $location.search 'property_id', undefined

  #
  # Center on an area if requested, or other special bounds to center on
  #
  checkCenterOnBounds = () ->
    areaId = $state.params.area_id || $location.search().area_id

    # we intend to center a subuser client to pins upon first login
    centerOnPins = rmapsClientEntryService.isFirstLogin()

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

    # center on pins if they exist; (subuser/client will have map_position populated from parent, which is used if no pins)
    else if centerOnPins and !_.isEmpty(rmapsPropertiesService.pins)
      rmapsClientEntryService.notFirstLoginAnymore()
      bounds = rmapsBounds.boundsFromPropertyArray(rmapsPropertiesService.pins)
      $timeout(() ->
        boundsReformat = [
          [bounds.northEast.lat, bounds.northEast.lng]
          [bounds.southWest.lat, bounds.southWest.lng]
        ]
        $rootScope.$emit rmapsEventConstants.map.fitBoundsProperty, boundsReformat, {padding: [80, 80]}
      )

  #
  # Set $scope variables for the Project selector tool
  #
  setScopeVariables = () ->
    $scope.loadProperty rmapsProfilesService.currentProfile
    checkCenterOnBounds()

  setScopeVariables()
