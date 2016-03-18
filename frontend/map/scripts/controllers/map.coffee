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

app.controller 'rmapsMapCtrl', ($scope, $rootScope, $location, $timeout, $http, $modal, $q, $window, $state, rmapsMapFactory,
  rmapsMainOptions, rmapsMapTogglesFactory, rmapsEventConstants, rmapsProjectsService, rmapsProfilesService
  rmapsParcelEnums, rmapsPropertiesService, $log, rmapsSearchboxService) ->

  $log = $log.spawn("map:controller")
  $log.debug "!!!! Create Maps Controller !!!!"

  $scope.satMap = {}#accessor to satMap so that satMap is in the scope chain for resultsFormatter

  $scope.init = (pageClass) ->
    $scope.pageClass = pageClass
  #end inits

  rmapsSearchboxService('mainMap')

  # If a new project is added or removed on the dashboard or elsewhere, this event will fire
  $rootScope.$onRootScope rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    $scope.loadIdentity identity

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, identity) ->
    $scope.loadIdentity identity

  getProjects = (identity) ->
    $scope.projects = _.values identity.profiles
    $scope.totalProjects = $scope.projects.length
    _.each $scope.projects, (project) ->
      project.totalProperties = (_.keys project.properties_selected)?.length
      project.totalFavorites = (_.keys project.favorites)?.length

  $scope.loadIdentity = (identity, project_id) ->
    $log.debug "loadIdentity"
    if identity?.currentProfileId? or project_id?
      getProjects identity
      projectToLoad = (_.find identity.profiles, project_id: project_id) or uiProfile(identity)
      $scope.loadProject projectToLoad

  $scope.loadProperty = (project) ->
    selectedResultId = $state.params.property_id or project.map_results?.selectedResultId

    if selectedResultId?.match(/\w+_\w*_\w+/) and map?
      $log.debug 'attempting to reinstate selectedResult', selectedResultId

      $location.search 'property_id', selectedResultId

#      rmapsPropertiesService.getPropertyDetail(
#        map.scope.refreshState(map_results: selectedResultId: selectedResultId),
#        rm_property_id: selectedResultId, 'all'
#      ).then (result) ->
#        return if _.isString result #not sure how this was happening but if we get it bail (should be an object)
#        $timeout () ->
#          map.scope.selectedResult = _.extend {}, map.scope.selectedResult, result
#        , 50
#        resultCenter = new Point(result.coordinates[1],result.coordinates[0])
#        resultCenter.zoom = 18
#        map.scope.map.center = resultCenter
#      .catch () ->
#        $location.search 'property_id', undefined
#        newState = map.scope.refreshState(map_results: selectedResultId: undefined)
#        rmapsPropertiesService.updateMapState newState
#    else
#      $location.search 'property_id', undefined

  $scope.loadProject = (project) ->
    $log.debug 'loadProject()', project, $scope.selectedProject
    if project == $scope.selectedProject
      return

    $scope.selectedProject = project
    $location.search 'project_id', project.project_id

    rmapsProfilesService.setCurrentProfile project
    .then () ->
      $log.debug "!!! PROFILE PROJECT CHANGED"

      if !$scope.map?
        map = new rmapsMapFactory($scope)

      $scope.loadProperty(project)

  #
  # Load data when the controller initially loads
  #

  $log.debug "Get principal identity"
  $rootScope.principal.getIdentity()
  .then (identity) ->
    $scope.loadIdentity identity, Number($state.params.project_id)

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
