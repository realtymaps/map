mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.fipsCodes.root
fipsRoutes = backendRoutes.fipsCodes

mod.service 'rmapsFipsCodesService', ($log, $http) ->
  $log = $log.spawn("map:rmapsFipsCodes")

  getAll: (data = {}) ->
    $http.postData(apiBase, data)

  getAllMlsCodes: (data = {}) ->
    $http.postData(fipsRoutes.getAllMlsCodes, data)

  getAllSupportedMlsCodes: (data = {}) ->
    $http.postData(fipsRoutes.getAllSupportedMlsCodes, data)

  getForUser: () ->
    $http.getData(fipsRoutes.getForUser)
