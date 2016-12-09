app = require '../../app.coffee'
replaceCCModalTemplate = require('../../../html/views/templates/modals/replaceCC.jade')()
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', (
$rootScope
$scope
$log
$uibModal
$q
rmapsSubscriptionService
rmapsFipsCodesService
rmapsMainOptions
) ->
  $log = $log.spawn("map:userSubscription")

  $scope.processing = 0
  $scope.data =
    fips: null

  $scope.showSubscription = () ->
    return ($scope.subscription? && $scope.subscription.status != 'expired' && $scope.subscription.plan.id != 'deactivated')

  $scope.isDeactivated = () ->
    return $scope.subscription?.plan?.id == rmapsMainOptions.plan.DEACTIVATED && ($rootScope.identity.user.stripe_plan_id in rmapsMainOptions.plan.PAID_LIST)

  $scope.isExpired = () ->
    return $scope.subscription?.status == rmapsMainOptions.plan.EXPIRED && ($rootScope.identity.user.stripe_plan_id in rmapsMainOptions.plan.PAID_LIST)

  $scope.unsubscribe = () ->
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirmDeactivate.jade')()

    $scope.deactivation =
      reason: null

    $scope.showCancelButton = true
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      $scope.processing++
      rmapsSubscriptionService.deactivate($scope.deactivation.reason)
      .then (subscription) ->
        if subscription? then $scope.subscription = subscription
      .finally () ->
        modalInstance.close()
        $scope.processing--

  $scope.upgrade = () ->
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirm.jade')()

    $scope.showCancelButton = true
    $scope.modalTitle = "Upgrade to Premium?"
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      $scope.processing++
      modalInstance.close()
      rmapsSubscriptionService.updatePlan(rmapsMainOptions.plan.PRO)
      .then (res) ->
        $rootScope.identity.subscription = res.plan.id
        $scope.subscription = res
      .finally () ->
        $scope.processing--

  $scope.reactivate = (opts = {needCard: false}) ->

    needCard = $scope.isExpired()

    console.log "\nreactivate()"
    console.log "opts: #{JSON.stringify(opts)}"
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirm.jade')()

    $scope.showCancelButton = true
    $scope.modalTitle = "Reactivating subscription..."
    if needCard
      $scope.modalBody = "You will be prompted to enter credit card information."
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      $scope.processing++

      # reactivatePlan = $rootScope.identity?.user?.stripe_plan_id
      $scope.payment = null
      if needCard
        modalInstanceCC = $uibModal.open
          animation: true
          template: replaceCCModalTemplate
          controller: 'rmapsReplaceCCModalCtrl'
          resolve:
            modalTitle: () ->
              return "New Credit Card"

            showCancelButton: () ->
              return null

        ccPromise = modalInstanceCC.result
        .then (result) ->
          console.log "result:\n#{JSON.stringify(result)}"
          if !result then return null
          return result
        .catch () ->
          return "error"
      else
        ccPromise = $q.when(null)


      # if ($rootScope.identity.subscription in [rmapsMainOptions.plan.PRO, rmapsMainOptions.plan.STANDARD] &&
      #   $scope.subscription.
      ccPromise
      .then (ccInfo) ->
        console.log "ccInfo: #{JSON.stringify(ccInfo)}"
        if !ccInfo? && needCard
          $scope.modalBody = "Invalid credit card info."
        else if ccInfo == "error"
          $scope.modelBody = "An error occured while updating payment info."
        else
          rmapsSubscriptionService.reactivate()
          .then (res) ->
            console.log "reactivated...\nres:\n#{JSON.stringify(res,null,2)}"
            $rootScope.identity.subscription = res.plan.id
            $scope.subscription = res
            $scope.modalBody = "Your #{res.plan.id} subscription has been renewed."
            $scope.modalOk = ->
              modalInstance.close()
            $scope.showCancelButton = false

          .catch () ->
            $scope.modalBody = "There was an issue while renewing your subscription.  Please contact customer service."
            $scope.modalOk = ->
              modalInstance.close()
      .finally () ->
        $scope.processing--

  $scope.processing++
  rmapsSubscriptionService.getSubscription()
  .then (subscription) ->
    console.log "subscription:\n#{JSON.stringify(subscription,null,2)}"
    console.log "rootScope:"
    console.log $rootScope
    console.log "$rootScope.subscrPlans: #{JSON.stringify($rootScope.subscrPlans)}"
    console.log "$rootScope.identity.subscription: #{$rootScope.identity.subscription}"
    $scope.subscription = subscription
  .finally () ->
    $scope.processing--

  $scope.processing++
  rmapsFipsCodesService.getForUser()
  .then (fipsData) ->
    $scope.data.fips = fipsData
  .finally () ->
    $scope.processing--
