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

  $scope.satMap = {}#accessor to satMap so that satMap is in the scope chain for resultsFormatter

  $scope.init = (pageClass) ->
    $scope.pageClass = pageClass
  #end inits

  rmapsSearchboxService('mainMap')

  # If a new project is added or removed on the dashboard or elsewhere, this event will fire
  $rootScope.$onRootScope rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    $scope.loadIdentity identity

  getProjects = (identity) ->
    $scope.projects = _.values identity.profiles
    $scope.totalProjects = $scope.projects.length
    _.each $scope.projects, (project) ->
      project.totalProperties = (_.keys project.properties_selected)?.length
      project.totalFavorites = (_.keys project.favorites)?.length

  $scope.loadIdentity = (identity, project_id) ->
    if identity?.currentProfileId? and project_id?
      getProjects identity
      projectToLoad = (_.find identity.profiles, project_id: project_id) or uiProfile(identity)
      $scope.loadProject projectToLoad

  $scope.loadProperty = (property) ->
    selectedResultId = $state.params.property_id or $scope.selectedProject.map_results?.selectedResultId

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
    if project == $scope.selectedProject
      return

    # If switching projects, ensure the old one is up-to-date
#    if $scope.selectedProject
#      $scope.selectedProject.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
#      $scope.selectedProject.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? and status
#      $scope.selectedProject.map_position = center: NgLeafletCenter(_.pick $scope.map.center, ['lat', 'lng', 'zoom'])
#      $scope.selectedProject.properties_selected = _.mapValues rmapsPropertiesService.getSavedProperties(), 'savedDetails'

    rmapsProfilesService.setCurrentProfile project
    .then () ->
      $log.debug "!!! PROFILE PROJECT CHANGED"
      $scope.selectedProject = project

      $location.search 'project_id', project.project_id

      $rootScope.selectedFilters = {}

#      map_position = project.map_position
#      #fix messed center
#      if !map_position?.center?.lng or !map_position?.center?.lat
#        map_position =
#          center:
#            lat: 26.129241
#            lng: -81.782227
#            zoom: 15
#
#      map_position =
#        center: NgLeafletCenter map_position.center

      if project.filters
        statusList = project.filters.status || []
        for key,status of rmapsParcelEnums.status
          project.filters[key] = (statusList.indexOf(status) > -1) or (statusList.indexOf(key) > -1)
        #TODO: this is a really ugly hack to workaround our poor state design in our app
        #filters and mapState need to be combined, also both should be moved to rootScope
        #the omits here are to keep from saving off duplicate data where project.filters is from the backend
        _.extend($rootScope.selectedFilters, _.omit(project.filters, ['status', 'current_project_id']))

      if $scope.map?
#        if map_position?.center?
#          $log.debug "Project changed and map factory exists, recentering map"
#          $scope.map.center = NgLeafletCenter(map_position.center or rmapsMainOptions.map.options.json.center)
#        if map_position?.zoom?
#          $scope.map.center.zoom = Number map_position.zoom
        $scope.rmapsMapTogglesFactory = new rmapsMapTogglesFactory(project.map_toggles)
      else
#        if map_position?
#          $log.debug "Project set first time, recentering map"
#          if map_position.center? and
#          map_position.center.latitude? and
#          map_position.center.latitude != 'NaN' and
#          map_position.center.longitude? and
#          map_position.center.longitude != 'NaN'
#            rmapsMainOptions.map.options.json.center = NgLeafletCenter map_position.center
#          if map_position.zoom?
#            rmapsMainOptions.map.options.json.center.zoom = +map_position.zoom

        rmapsMainOptions.map.toggles = new rmapsMapTogglesFactory(project.map_toggles)
        map = new rmapsMapFactory($scope)

      $scope.loadProperty()

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
