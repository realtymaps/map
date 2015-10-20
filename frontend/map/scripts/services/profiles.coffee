app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'properties_selected']


app.service 'rmapsCurrentProfilesService', ($http) ->
  setCurrent: (profile) ->
    $http.post(backendRoutes.userSession.currentProfile, currentProfileId: profile.id)

app.service 'rmapsProfilesService', ($http, rmapsprincipal, rmapsCurrentProfilesService) ->
  _currentProfSvc = rmapsCurrentProfilesService

  _update = (profile) ->
    $http.put(backendRoutes.userSession.profiles,_.pick(profile, _updateProfileAttrs))

  setCurrent: (oldProfile, newProfile) ->
    _update(oldProfile)
    .then () ->
      _currentProfSvc.setCurrent(newProfile)
    .then () ->
      rmapsprincipal.getCurrentProfile(newProfile.id)
