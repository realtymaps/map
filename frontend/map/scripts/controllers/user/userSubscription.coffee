app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', ($rootScope, $scope, $log, rmapsSubscriptionService) ->
  $log = $log.spawn("map:userSubscription")

  $scope.unsubscribe = () ->
    rmapsSubscriptionService.deactivate()
    .then (subscription) ->
      $scope.subscription = subscription

  rmapsSubscriptionService.getSubscription()
  .then (subscription) ->
    $scope.subscription = subscription
