app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', ($rootScope, $scope, $log, rmapsPlansService) ->
  $log = $log.spawn("map:userSubscription")

  $scope.unsubscribe = () ->
    rmapsPlansService.deactivate()
    .then (plan) ->
      $scope.plan = plan

  rmapsPlansService.getPlan()
  .then (plan) ->
    $scope.plan = plan
