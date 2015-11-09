app = require '../app.coffee'
require '../factories/map.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{Point, NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
{uiProfile} = require('../../../../common/utils/util.profile.coffee')

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined


module.exports = app

app.controller 'rmapsMapCtrl', ($scope, $rootScope, $location, $timeout, $http, $modal, $q, $window, $state, rmapsMap,
  rmapsMainOptions, rmapsMapToggles, rmapsprincipal, rmapsevents, rmapsProjectsService, rmapsProfilesService
  rmapsParcelEnums, rmapsPropertiesService, nemSimpleLogger, rmapssearchbox) ->

  $log = nemSimpleLogger.spawn("map:controller")

  $scope.satMap = {}#accessor to satMap so that satMap is in the scope chain for resultsFormatter
  #ng-inits or inits
  #must be defined pronto as they will be skipped if you try to hook them to factories
  $scope.resultsInit = (resultsListId) ->
    $scope.resultsListId = resultsListId

  $scope.init = (pageClass) ->
    $scope.pageClass = pageClass
  #end inits

  rmapssearchbox('mainMap')

  $scope.loadIdentity = (identity, project_id) ->
    if not identity?.currentProfileId and not project_id
      $location.path(frontendRoutes.profiles)
    else
      $scope.projects = identity.profiles
      $scope.totalProjects = (_.keys identity.profiles).length
      _.each $scope.projects, (project) ->
        project.totalProperties = (_.keys project.properties_selected).length

      projectToLoad = (_.find identity.profiles, project_id: project_id) or uiProfile(identity)
      $scope.loadProject projectToLoad

  $scope.loadProject = (project) ->
    if project == $scope.selectedProject
      return

    # If switching projects, ensure the old one is up-to-date
    if $scope.selectedProject
      $scope.selectedProject.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
      $scope.selectedProject.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? and status
      $scope.selectedProject.map_position = center: NgLeafletCenter(_.pick $scope.map.center, ['lat', 'lng', 'zoom'])
      $scope.selectedProject.properties_selected = rmapsPropertiesService.getSavedProperties()

    rmapsProfilesService.setCurrent $scope.selectedProject, project
    .then () ->
      $scope.selectedProject = project

      $rootScope.selectedFilters = {}

      $scope.projectDropdown.isOpen = false

      map_position = project.map_position
      #fix messed center
      if !map_position?.center?.lng or !map_position?.center?.lat
        map_position =
          center:
            lat: 26.129241
            lng: -81.782227
            zoom: 15

      map_position =
        center: NgLeafletCenter map_position.center

      if project.filters
        statusList = project.filters.status || []
        for key,status of rmapsParcelEnums.status
          project.filters[key] = (statusList.indexOf(status) > -1) or (statusList.indexOf(key) > -1)
        _.extend($rootScope.selectedFilters, _.omit(project.filters, 'status'))
      if $scope.map?
        if map_position?.center?
          $scope.map.center = NgLeafletCenter(map_position.center or rmapsMainOptions.map.options.json.center)
        if map_position?.zoom?
          $scope.map.center.zoom = Number map_position.zoom
        $scope.rmapsMapToggles = new rmapsMapToggles(project.map_toggles)
      else
        if map_position?
          if map_position.center? and
          map_position.center.latitude? and
          map_position.center.latitude != 'NaN' and
          map_position.center.longitude? and
          map_position.center.longitude != 'NaN'
            rmapsMainOptions.map.options.json.center = NgLeafletCenter map_position.center
          if map_position.zoom?
            rmapsMainOptions.map.options.json.center.zoom = +map_position.zoom

        rmapsMainOptions.map.toggles = new rmapsMapToggles(project.map_toggles)
        map = new rmapsMap($scope)

      if project.map_results?.selectedResultId? and map?
        $log.debug 'attempting to reinstate selectedResult'
        rmapsPropertiesService.getPropertyDetail(null,
          rm_property_id: project.map_results.selectedResultId, 'all')
        .then (data) ->
          map.scope.selectedResult = _.extend map.scope.selectedResult or {}, data

  $scope.projectDropdown = isOpen: false

  $scope.enableNoteTap = ->
    $scope.Toggles.enableNoteTap()

  $scope.selectProject = (project) ->
    $state.go $state.current, 'project_id': project.project_id, { notify: false }
    $scope.loadProject project

  $scope.addProject = () ->
    $scope.newProject =
      copyCurrent: true
      name: ($scope.selectedProject.name or 'Sandbox') + ' copy'

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/addProjects.jade')()

    modalInstance.result.then (result) ->

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')
      rmapsProjectsService.createProject $scope.newProject
      .then (response) ->
        rmapsprincipal.setIdentity response.data.identity
        $scope.loadIdentity response.data.identity

  $scope.archiveProject = (project) ->
    rmapsProjectsService.update id: project.project_id, archived: !project.archived
    .then () ->
      $scope.projectDropdown.isOpen = false

  $scope.resetProject = (project) ->
    if confirm 'Clear all filters, saved properties, and notes?'
      rmapsProjectsService.delete id: project.project_id
      .then () ->
        $window.location.reload()

  #this kicks off eveything and should be called last
  $rootScope.registerScopeData () ->
    rmapsprincipal.getIdentity()
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
