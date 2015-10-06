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

#WE WILL STILL NEED THIS IN PRODUCTION FOR A GOOGLE APIKEY
#app.config(['uiGmapGoogleMapApiProvider', (GoogleMapApi) ->
#  GoogleMapApi.configure
#    # key: 'your api key',
#    v: '3.18'
#    libraries: 'visualization,geometry,places'
#])

app.controller 'rmapsMapCtrl', ($scope, $rootScope, $location, $timeout, $http, $modal, $q, rmapsMap,
  rmapsMainOptions, rmapsMapToggles, rmapsprincipal, rmapsevents,
  rmapsParcelEnums, rmapsProperties, nemSimpleLogger, rmapssearchbox) ->

  $log = nemSimpleLogger.spawn("map:controller")
  #ng-inits or inits
  #must be defined pronto as they will be skipped if you try to hook them to factories
  $scope.resultsInit = (resultsListId) ->
    $scope.resultsListId = resultsListId

  $scope.init = (pageClass) ->
    $scope.pageClass = pageClass
  #end inits

  rmapssearchbox('mainMap')

  $rootScope.registerScopeData () ->
    rmapsprincipal.getIdentity()
    .then $scope.loadIdentity

  $scope.loadIdentity = (identity) ->
    $scope.projects = identity.profiles
    $scope.projectsTotal = (_.keys $scope.projects).length
    _.each $scope.projects, (project) ->
      project.totalProperties = (_.keys project.properties_selected).length

    rmapsprincipal.getCurrentProfile()
    .then ->
      rmapsprincipal.getIdentity()
    .then (identity) ->
      $scope.loadProfile uiProfile(identity)

    if not identity?.currentProfileId
      $location.path(frontendRoutes.profiles)

  $scope.loadProfile = (profile) ->
    if profile == $scope.selectedProfile
      return

    deferred = $q.defer()
    # If switching profiles, ensure the old profile is saved
    if $scope.selectedProfile

      $scope.selectedProfile.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
      $scope.selectedProfile.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? and status
      $scope.selectedProfile.map_position = center: NgLeafletCenter(_.pick $scope.map.center, ['lat', 'lng', 'zoom'])

      $http.put(backendRoutes.userSession.profiles, _.pick($scope.selectedProfile, ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'properties_selected']))
      .then () ->
        # Set the current profile
        $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)
      .then () ->
        # Set the current profile
        rmapsprincipal.getCurrentProfile(profile.id)
      .then () ->
        deferred.resolve()
    else
      deferred.resolve()

    deferred.promise.then () ->
      $scope.selectedProfile = profile

      $rootScope.selectedFilters = {}

      $scope.projectDropdown.isOpen = false

      map_position = profile.map_position
      #fix messed center
      if !map_position?.center?.lng or !map_position?.center?.lat
        map_position =
          center:
            lat: 26.129241
            lng: -81.782227
            zoom: 15

      map_position =
        center: NgLeafletCenter map_position.center

      if profile.filters
        statusList = profile.filters.status || []
        for key,status of rmapsParcelEnums.status
          profile.filters[key] = (statusList.indexOf(status) > -1) or (statusList.indexOf(key) > -1)
        _.extend($rootScope.selectedFilters, _.omit(profile.filters, 'status'))
      if map
        if map_position?.center?
          $scope.map.center = NgLeafletCenter(map_position.center or rmapsMainOptions.map.options.json.center)
        if map_position?.zoom?
          $scope.map.center.zoom = Number map_position.zoom
        $scope.rmapsMapToggles = new rmapsMapToggles(profile.map_toggles)
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

        rmapsMainOptions.map.toggles = new rmapsMapToggles(profile.map_toggles)
        map = new rmapsMap($scope, rmapsMainOptions.map)

      if profile.map_results?.selectedResultId? and map?
        $log.debug 'attempting to reinstate selectedResult'
        rmapsProperties.getPropertyDetail(null,
          profile.map_results.selectedResultId, 'all')
        .then (data) ->
          map.scope.selectedResult = _.extend map.scope.selectedResult or {}, data

  $scope.projectDropdown = isOpen: false

  $scope.addProject = () ->
    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/addProjects.jade')()

    modalInstance.result.then (result) ->

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')
      $http.post backendRoutes.userSession.newProject, projectName: newProject.name.value
      .then (response) ->
        rmapsprincipal.setIdentity response.data.identity
        $scope.loadIdentity response.data.identity

  $scope.archiveProject = (project) ->
    project.project_archived = !project.project_archived
    $http.put backendRoutes.user_projects.root + "/#{project.project_id}",
      id: project.project_id
      name: project.project_name
      archived: project.project_archived
    .then () ->
      $scope.projectDropdown.isOpen = false

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
