app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{apiBase} = backendRoutes.notificationFrequencies

app.service 'rmapsNotificationFrequenciesService', ($http) ->

  getAll: (entity) ->
    $http.getData(apiBase, cache:true)
