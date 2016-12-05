app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', (
$rootScope
$scope
$log
$uibModal
rmapsSubscriptionService
rmapsFipsCodesService
rmapsMainOptions
) ->
  $log = $log.spawn("map:userSubscription")

  $scope.data =
    fips: null

  $scope.unsubscribe = () ->
    rmapsSubscriptionService.deactivate()
    .then (subscription) ->
      $scope.subscription = subscription

  $scope.upgrade = () ->
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirm.jade')()

    $scope.showCancelButton = true
    $scope.modalTitle = "Upgrade to Premium?"
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      console.log "ok!"
      console.log "rmapsMainOptions.plan:\n#{JSON.stringify(rmapsMainOptions.plan)}"
      modalInstance.close()
      rmapsSubscriptionService.setPlan('pro')
      .then (res) ->
        $rootScope.identity.subscription = res.plan.id
        $scope.subscription = res
        console.log "\nsetPlan response:\n#{JSON.stringify(res,null,2)}"


  rmapsSubscriptionService.getSubscription()
  .then (subscription) ->
    console.log "subscription:\n#{JSON.stringify(subscription,null,2)}"
    console.log "identity.subscription:\n#{$rootScope.identity.subscription}"
    $scope.subscription = subscription

  rmapsFipsCodesService.getForUser()
  .then (fipsData) ->
    console.log "fips data:\n#{JSON.stringify(fipsData)}"
    $scope.data.fips = fipsData