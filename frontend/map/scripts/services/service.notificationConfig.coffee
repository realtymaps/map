app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{apiBase} = backendRoutes.notificationsConfigSession

app.service 'rmapsNotificationConfigService', ($http) ->

  getAll: (entity) ->
    $http.getData(apiBase, cache:false)

  update: (entity) ->
    $http.post(apiBase, entity)
