app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'properties_selected']


app.service 'rmapsCurrentProfilesService', ($http) ->
  setCurrent: (profile) ->
    $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)

app.service 'rmapsProfilesService', ($http, $rootScope, rmapsPrincipalService, rmapsevents, rmapsCurrentProfilesService) ->
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
