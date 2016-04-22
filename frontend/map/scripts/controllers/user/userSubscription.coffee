app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', ($rootScope, $scope, $log, rmapsPlansService) ->
  $log = $log.spawn("map:userSubscription")

  $scope.unsubscribe = () ->
    rmapsPlansService.deactivate()
    .then (deactivatedPlan) ->
      $scope.plan = deactivatedPlan
      $scope.message = "Your account has been deactivated."

  rmapsPlansService.getPlan()
  .then (plan) ->
    $scope.plan = plan
