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
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirmDeactivate.jade')()

    $scope.deactivation =
      reason: null
    $scope.processing = false
    $scope.showCancelButton = true
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      $scope.processing = true
      rmapsSubscriptionService.deactivate($scope.deactivation.reason)
      .then (subscription) ->
        $scope.subscription = subscription
        $scope.processing = false
      .finally () ->
        modalInstance.close()

  $scope.upgrade = () ->
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirm.jade')()

    $scope.showCancelButton = true
    $scope.modalTitle = "Upgrade to Premium?"
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      modalInstance.close()
      rmapsSubscriptionService.setPlan(rmapsMainOptions.plan.PRO)
      .then (res) ->
        $rootScope.identity.subscription = res.plan.id
        $scope.subscription = res



  rmapsSubscriptionService.getSubscription()
  .then (subscription) ->
    $scope.subscription = subscription

  rmapsFipsCodesService.getForUser()
  .then (fipsData) ->
    $scope.data.fips = fipsData
