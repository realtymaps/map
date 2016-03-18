app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'properties_selected']
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')


app.service 'rmapsCurrentProfilesService', ($http) ->
  setCurrent: (profile) ->
    $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)

app.service 'rmapsProfilesService', (
  $http,
  $log
  $q,
  $rootScope,
  rmapsCurrentProfilesService,
  rmapsEventConstants,
  rmapsMainOptions,
  rmapsMapFactory,
  rmapsMapTogglesFactory,
  rmapsParcelEnums,
  rmapsPrincipalService,
  rmapsPropertiesService,
) ->

  $log = $log.spawn "rmapsProfileService"

  _currentProfSvc = rmapsCurrentProfilesService

  _update = (profile) ->
    $http.put(backendRoutes.userSession.profiles,_.pick(profile, _updateProfileAttrs))

  _current = (profile) ->
    _currentProfSvc.setCurrent profile
    .then () ->
      rmapsPrincipalService.setCurrentProfile profile

  setCurrent: (oldProfile, newProfile) ->
    if oldProfile?
      _update(oldProfile)
      .then () ->
        _current newProfile
    else
      _current newProfile

  currentProfile: null

  setCurrentProfileByProjectId: (project_id) ->
    project_id = Number(project_id) if _.isString project_id
    rmapsPrincipalService.getIdentity()
    .then (identity) =>
      profile = (_.find(identity.profiles, project_id: project_id))
      return @setCurrentProfile profile

  setCurrentProfile: (project) ->
    if project == @currentProfile
      return $q.resolve project

    # If switching projects, ensure the old one is up-to-date
    if @currentProfile
      @currentProfile.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
      @currentProfile.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? and status
      @currentProfile.properties_selected = _.mapValues rmapsPropertiesService.getSavedProperties(), 'savedDetails'

      # Get the center of the main map if it has been created
      if rmapsMapFactory.currentMainMap
        @currentProfile.map_position = center: NgLeafletCenter(_.pick rmapsMapFactory.currentMainMap.scope?.map?.center, ['lat', 'lng', 'zoom'])

    # Save the old and load the new projects
    return @setCurrent @currentProfile, project
    .then () =>
      $log.debug "Set current profile to: #{project.project_id}"
      @currentProfile = project

      # Center and zoom the map for the new project
      map_position = project.map_position

      #
      # Center and zoom map to Project
      #

      #fix messed center
      if !map_position?.center?.lng or !map_position?.center?.lat
        map_position =
          center:
            lat: 26.129241
            lng: -81.782227
            zoom: 15

      map_position =
        center: NgLeafletCenter map_position.center

      if rmapsMapFactory.currentMainMap?.scope?.map?
        if map_position?.center?
          $log.debug "Project changed and map factory exists, recentering map"
          rmapsMapFactory.currentMainMap.scope.map.center = NgLeafletCenter(map_position.center or rmapsMainOptions.map.options.json.center)
        if map_position?.zoom?
          rmapsMapFactory.currentMainMap.scope.map.center.zoom = Number map_position.zoom
      else
        if map_position?
          $log.debug "Project set first time, recentering map"
          if map_position.center? and
          map_position.center.latitude? and
          map_position.center.latitude != 'NaN' and
          map_position.center.longitude? and
          map_position.center.longitude != 'NaN'
            rmapsMainOptions.map.options.json.center = NgLeafletCenter map_position.center
          if map_position.zoom?
            rmapsMainOptions.map.options.json.center.zoom = +map_position.zoom

      #
      # Handle project filters
      #

      $rootScope.selectedFilters = {}

      if project.filters
        statusList = project.filters.status || []
        for key,status of rmapsParcelEnums.status
          project.filters[key] = (statusList.indexOf(status) > -1) or (statusList.indexOf(key) > -1)
        #TODO: this is a really ugly hack to workaround our poor state design in our app
        #filters and mapState need to be combined, also both should be moved to rootScope
        #the omits here are to keep from saving off duplicate data where project.filters is from the backend
        _.extend($rootScope.selectedFilters, _.omit(project.filters, ['status', 'current_project_id']))

      #
      # Set the Filter toggles based on the current project
      #

      if rmapsMapFactory.currentMainMap?
        rmapsMapFactory.currentMainMap.updateToggles project.map_toggles
      else
        rmapsMainOptions.map.toggles = new rmapsMapTogglesFactory(project.map_toggles)

      return project
