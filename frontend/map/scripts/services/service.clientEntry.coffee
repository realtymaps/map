app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
clientEntryAPI = backendRoutes.clientEntry

app.service 'rmapsClientEntryService', ($http, $sce) ->
  _clientFirstLogin = false

  getClientEntry: (key) ->
    $http.get clientEntryAPI.getClientEntry,
      params:
        key: key
      cache: false
    .then ({data}) ->
      if data.project.sandbox
        data.project.name = "Sandbox"
      data

  setPasswordAndBounce: (entity) ->
    $http.post backendRoutes.clientEntry.setPasswordAndBounce, entity
    .then (response) ->
      _clientFirstLogin = true
      response

  isFirstLogin: () ->
    return _clientFirstLogin

  notFirstLoginAnymore: () ->
    _clientFirstLogin = false

