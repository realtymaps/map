mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
mlsRoutes = backendRoutes.mls

mod.service 'rmapsMlsService', ($log, $http) ->
  $log = $log.spawn("map:rmapsFipsCodes")

  getAll: (data = {}) ->
    $http.postData(mlsRoutes.root, data)

  getAllSupported: (data = {}) ->
    $http.postData(mlsRoutes.supported, data)

  getSupportedStates: () ->
    $http.getData(mlsRoutes.supportedStates)

  getSupportedPossibleStates: () ->
    $http.getData(mlsRoutes.supportedPossibleStates)
