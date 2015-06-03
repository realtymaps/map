app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'mlsConfig', ($http) ->
  getDatabaseList = (url, username, password, cache=true) ->
    mlsUrl = "#{backendRoutes.mls.getDatabaseList}"
    $http.get(mlsUrl, cache)

  getTableList = (url, username, password, database, cache=true) ->
    mlsUrl = "#{backendRoutes.mls.getTableList}"
    $http.get(mlsUrl, cache)

  getFieldList = (url, username, password, database, table, cache=true) ->
    mlsUrl = "#{backendRoutes.mls.getTableList}"
    $http.get(mlsUrl, cache)

  saveMlsConfig = (config, cache) ->
    mlsUrl = "#{backendRoutes.mls.saveConfig}"
    $http.post(mlsUrl, cache)