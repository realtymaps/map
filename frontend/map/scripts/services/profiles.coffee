app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'properties_selected']
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')


app.service 'rmapsCurrentProfilesService', ($http) ->
  setCurrent: (profile) ->
    $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)

app.service 'rmapsProfilesService', ($http, $rootScope, rmapsPrincipalService, rmapsEventConstants, rmapsCurrentProfilesService, rmapsMapFactory, rmapsPropertiesService, rmapsParcelEnums, $log) ->
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

    return @setCurrent @selectedProfile, project
    .then () ->

      @selectedProfile = project

      $log.debug "Set current profile to: #{project.project_id}"

      return project
