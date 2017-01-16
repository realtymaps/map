app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{apiBase} = backendRoutes.notificationMethods

app.service 'rmapsNotificationMethodsService', ($http) ->

  getAll: (entity) ->
    $http.getData(apiBase, cache:true)
