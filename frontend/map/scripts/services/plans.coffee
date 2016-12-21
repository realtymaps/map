app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
planAPI = backendRoutes.plans.apiBase

app.service 'rmapsPlansService', ($http) ->
  getList: () ->
    $http.get planAPI, cache: true
    .then ({data}) ->
      data
