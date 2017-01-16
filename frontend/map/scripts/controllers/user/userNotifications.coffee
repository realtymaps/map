app = require '../../app.coffee'
module.exports = app
_ = require 'lodash'

app.controller 'rmapsUserNotificationsCtrl', (
$scope, $log
rmapsNotificationConfigService
rmapsNotificationFrequenciesService
rmapsNotificationMethodsService) ->

  $scope.typesMap = {
    propertySaved:
      type: "Property Saves & Un-Saves"
      detail: "Notes, Pins/Saves, Favorites"
    jobQueue1:
      type: "Job Queue"
  }


  $log = $log.spawn("map:userNotifications")

  $scope.sortReverse = true
  $scope.sortField = 'type'

  rmapsNotificationMethodsService.getAll

  toLoad = {
    notifications: rmapsNotificationConfigService.getAll
    frequencies: rmapsNotificationFrequenciesService.getAll
    methods: rmapsNotificationMethodsService.getAll
  }

  _.each toLoad, (v, k) ->
    v().then (data) -> $scope[k] = data


  $scope.update = (model) ->
    rmapsNotificationConfigService.update(model)


  return
