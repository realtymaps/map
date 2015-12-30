app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.us_states.root

app.service 'rmapsUsStates', ($log, $http) ->
  $log = $log.spawn("map:rmapsUsStates")

  getAll: () ->
    $http.get(apiBase).then ({data}) ->
      data
