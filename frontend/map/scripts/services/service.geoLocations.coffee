app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsGeoLocations', ($log, $http) ->
  $log = $log.spawn("map:rmapsGeoLocations")

  states: () ->
    $http.get(backendRoutes.us_states.root)
    .then ({data}) ->
      data
