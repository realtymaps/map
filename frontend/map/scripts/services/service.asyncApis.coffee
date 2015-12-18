app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

apiBase = backendRoutes.config.asyncAPIs

app.service 'rmapsAsyncAPIsService', ($http, $q) ->

  deferred = null

  _reset = () ->
    deferred = $q.defer()

  _reset()

  getDeferred: (reset = false) ->
    _reset() if reset
    deferred

  getAll: () ->
    $http.get apiBase
    .then ({data}) ->
      data
