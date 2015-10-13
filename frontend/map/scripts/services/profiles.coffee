app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_updateProfileAttrs = ['id', 'filters', 'map_position', 'map_results', 'map_toggles', 'properties_selected']


app.service 'rmapsCurrentProfilesService', ($http) ->
  setCurrent: (id) ->
    $http.post(backendRoutes.userSession.currentProfile, currentProfileId: id)

app.service 'rmapsProfilesService', ($http, rmapsprincipal, rmapsCurrentProfilesService) ->
  _currentProfSvc = rmapsCurrentProfilesService

  _update = (selectedProfile) ->
    $http.put(backendRoutes.userSession.profiles,_.pick(selectedProfile, _updateProfileAttrs))

  setCurrent: (selectedProfile) ->
    _update(selectedProfile)
    .then () ->
      _currentProfSvc.setCurrent(selectedProfile.id)
    .then () ->
      rmapsprincipal.getCurrentProfile(selectedProfile.id)
