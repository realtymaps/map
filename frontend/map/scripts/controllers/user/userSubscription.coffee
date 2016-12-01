app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', ($rootScope, $scope, $log, rmapsSubscriptionService, rmapsFipsCodesService) ->
  $log = $log.spawn("map:userSubscription")

  $scope.data =
    fips: null

  $scope.unsubscribe = () ->
    rmapsSubscriptionService.deactivate()
    .then (subscription) ->
      $scope.subscription = subscription

  $scope.upgrade = () ->

  rmapsSubscriptionService.getSubscription()
  .then (subscription) ->
    console.log "subscription:\n#{JSON.stringify(subscription,null,2)}"
    $scope.subscription = subscription

  rmapsFipsCodesService.getForUser()
  .then (fipsData) ->
    console.log "fips data:\n#{JSON.stringify(fipsData)}"
    $scope.data.fips = fipsData