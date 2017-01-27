_ = require 'lodash'
app = require '../../app.coffee'

module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', (
  $rootScope
  $scope
  $log
  $uibModal
  $q
  rmapsSubscriptionService
  rmapsFipsCodesService
  rmapsPaymentMethodService
  rmapsMainOptions
  rmapsUserFeedbackCategoryService
  rmapsUserFeedbackSubcategoryService
  rmapsCreditCardService
  rmapsCreditCardFactory
) ->
  $log = $log.spawn("map:userSubscription")

  creditCardFact = rmapsCreditCardFactory($scope)

  $scope.data.fips = null

  # TODO: possibly move to run-root-scopt-init , one issue making this tougehr is $scope.subscription
  #
  # tests / flags
  #
  $scope.showSubscription = () ->
    # subscription status of `expired` or `deactivated` isn't represented by stripe subscr object, so forego using the stripe subscription
    return ($scope.subscription? && !($rootScope.identity.subscriptionStatus in [rmapsMainOptions.subscription.STATUS.EXPIRED, rmapsMainOptions.subscription.STATUS.DEACTIVATED]))

  $scope.isDeactivated = () ->
    return $rootScope.identity.subscriptionStatus == rmapsMainOptions.subscription.STATUS.DEACTIVATED &&
      ($rootScope.identity.user.stripe_plan_id in rmapsMainOptions.subscription.PLAN.PAID_LIST)

  $scope.isExpired = () ->
    return $rootScope.identity.subscriptionStatus == rmapsMainOptions.subscription.STATUS.EXPIRED &&
      ($rootScope.identity.user.stripe_plan_id in rmapsMainOptions.subscription.PLAN.PAID_LIST)

  $scope.isInGracePeriod = () ->
    # did user cancel, but we're still active
    return $scope.subscription?.canceled_at? && !$scope.subscription?.ended_at?

  $scope.isWarningStatus = (status) ->
    return !(status in [rmapsMainOptions.subscription.STATUS.ACTIVE, rmapsMainOptions.subscription.STATUS.TRIALING])

  $q.all(
    subcategories: rmapsUserFeedbackSubcategoryService.get())
  .then (results) ->
    $scope.subcategories = _.filter(results.subcategories, {category: 'deactivation'})

  #
  # Account actions
  #
  $scope.unsubscribe = () ->
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirmDeactivate.jade')()

    $scope.deactivation =
      subcategory: null
      details: null

    $scope.showCancelButton = true
    $scope.modalCancel = modalInstance.dismiss
    $scope.modalOk = () ->
      $scope.processing++
      rmapsSubscriptionService.deactivate($scope.deactivation)
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
      rmapsSubscriptionService.updatePlan(rmapsMainOptions.subscription.PLAN.PRO)
      .then (res) ->
        $rootScope.identity.subscriptionStatus = res.status
        $scope.subscription = res
      .finally () ->
        $scope.processing--


  $scope.reactivate = ({needCard} = {}) ->
    $scope.modalDisable = false
    # flag that lets us know if expired or not (expired means we need CC)
    needCard ?= $scope.isExpired()

    # reactivate modal context
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../../html/views/templates/modals/confirm.jade')()
    $scope.showCancelButton = true
    $scope.modalTitle = "Reactivating subscription..."

    if needCard
      $scope.modalBody = "You will be prompted to enter credit card information."

    $scope.modalCancel = modalInstance.dismiss

    # confirmed reactivate...
    $scope.modalOk = () ->
      $scope.processing++

      # credit-card modal context
      if needCard
        # all credit-card updating is handled within this modal/template, so no need to pass cc source around.
        ccPromise = $scope.replaceCC()
      else
        ccPromise = $q.when(null)

      # process reactivation
      ccPromise
      .then (ccInfo) ->
        $scope.modalDisable = true
        $scope.modalBody = "Please do not close this window during processing..."

        # if we needed a CC, but the info is null, the CC form must've been unsuccessful or exited.
        if needCard && !ccInfo?
          $scope.modalBody = "Invalid credit card info."

        # if an error occured, indicate that
        else if ccInfo == "error"
          $scope.modelBody = "An error occured while updating payment info."

        # proceed with reactivation, our CC will be updated if we needed one
        else
          rmapsSubscriptionService.reactivate()
          .then (res) ->
            # update subscription, and modal context with success content
            $rootScope.identity.subscriptionStatus = res.status
            $scope.subscription = res
            $scope.modalBody = "Your #{res.plan.id} subscription has been renewed."
            $scope.modalDisable = false
            $scope.modalOk = ->
              modalInstance.close()
            $scope.showCancelButton = false

          .catch () ->
            # update modal context with error content
            $scope.modalBody = "There was an issue while renewing your subscription.  Please contact customer service."
            $scope.modalDisable = false
            $scope.modalOk = ->
              modalInstance.close()

      .finally () ->
        $scope.processing--
      .then ->
        creditCardFact.getAllPayments()



  creditCardFact.process rmapsSubscriptionService.getSubscription()
  .then (subscription) ->
    $scope.subscription = subscription

  creditCardFact.process rmapsFipsCodesService.getForUser()
  .then (fips) ->
    $scope.data.fips = fips

  creditCardFact.process rmapsPaymentMethodService.getDefault(cache:false)
  .then (source) ->
    $scope.data.payment = source
