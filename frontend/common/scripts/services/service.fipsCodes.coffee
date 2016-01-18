mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.fipsCodes.root
serviceName = 'rmapsFipsCodes'

mod.service serviceName, ($log, $http) ->
  $log = $log.spawn("frontend:map:#{serviceName}")

  @getAllByState = (stateName) ->
    throw new Error("stateName must be defined") unless stateName
    $http.get("#{apiBase}/state/#{stateName}").then ({data}) ->
      data

  @
