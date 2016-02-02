mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.fipsCodes.root
fipsRoutes = backendRoutes.fipsCodes

mod.service 'rmapsFipsCodesService', ($log, $http) ->
  $log = $log.spawn("frontend:map:rmapsFipsCodes")

  @getAllByState = (stateName) ->
    throw new Error("stateName must be defined") unless stateName
    $http.get("#{apiBase}/state/#{stateName}").then ({data}) ->
      data

  @getByMlsCode = (mlsCode) ->
    throw new Error("mlsCode must be defined") unless mlsCode
    $http.get(fipsRoutes.getByMlsCode.replace(':mls_code',mlsCode))
    .then ({data}) ->
      data

  @getAllMlsCodes = () ->
    $http.get(fipsRoutes.getAllMlsCodes)
    .then ({data}) ->
      data

  @
