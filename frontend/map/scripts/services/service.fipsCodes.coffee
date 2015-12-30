app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.fipsCodes.root
serviceName = 'rmapsFipsCodes'

app.service serviceName, ($log, $http) ->
  $log = $log.spawn("map:#{serviceName}")

  @getAllByState = (stateName) ->
    throw new Error("stateName must be defined") unless stateName
    $http.get("#{apiBase}/state/#{stateName}").then ({data}) ->
      data

  @
