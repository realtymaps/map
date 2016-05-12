app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
clientEntryAPI = backendRoutes.clientEntry

app.service 'rmapsClientEntryService', ($http, $sce) ->
  getClientEntry: (key) ->
    $http.get clientEntryAPI.getClientEntry,
      params:
        key: key
      cache: false
    .then ({data}) ->
      if data.project.sandbox
        data.project.name = "Sandbox"
      data
