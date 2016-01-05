app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsPlansService', ($http) ->
  {apiBase} = backendRoutes.plans

  getList: () ->
    $http.get(apiBase, cache: true).then ({data}) ->
      data
