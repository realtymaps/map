app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.charges

app.service 'rmapsChargesService', ($http) ->

  get: (entity) ->
    $http.get apiBase.getHistory, entity
    .then ({data}) ->
      console.log "data:\n#{JSON.stringify(data,null,2)}"
      data
