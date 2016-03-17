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

  selectedProfile: null
  setCurrentProfile: (project) ->
    if project == @selectedProfile
      return

    # If switching projects, ensure the old one is up-to-date
    if @selectedProfile
      @selectedProfile.filters = _.omit $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]?
      @selectedProfile.filters.status = _.keys _.pick $rootScope.selectedFilters, (status, key) -> rmapsParcelEnums.status[key]? and status
      @selectedProfile.properties_selected = _.mapValues rmapsPropertiesService.getSavedProperties(), 'savedDetails'

      # Get the center of the main map if it has been created
      if rmapsMapFactory.currentMainMap
        @selectedProfile.map_position = center: NgLeafletCenter(_.pick rmapsMapFactory.currentMainMap.scope?.map?.center, ['lat', 'lng', 'zoom'])

    # Save the old and load the new projects
    return @setCurrent @selectedProfile, project
    .then () ->
      $log.debug "Set current profile to: #{project.project_id}"
      @selectedProfile = project

      # Center and zoom the map for the new project
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

      if rmapsMapFactory.currentMainMap?
        rmapsMapFactory.currentMainMap.updateToggles project.map_toggles
      else
        rmapsMainOptions.map.toggles = new rmapsMapTogglesFactory(project.map_toggles)

      return project
