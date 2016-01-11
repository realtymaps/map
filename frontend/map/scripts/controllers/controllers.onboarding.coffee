###global _:true, angular:true###
app = require '../app.coffee'

#TODO: see if using $state.is via siblings is a way of avoiding providers.onboarding
app.controller 'rmapsOnBoardingCtrl', ($log, $scope, $state, $stateParams, rmapsOnBoardingOrder, rmapsOnBoardingOrderSelector,
rmapsPlansService) ->

  $log = $log.spawn("frontend:map:rmapsOnBoardingCtrl")

  rmapsPlansService.getList().then (plans) ->
    _.merge $scope,
      view:
        plans: plans

  step = $state.current.name

  _.merge $scope, user: $stateParams,
    user: #constant model passed through all states
      submit: () ->
        $scope.view.showSteps = true
        if $scope.view.hasNextStep
          return $scope.view.goToNextStep()
        $log.debug("begin submitting user to onboarding service")
        $log.debug($scope.user)
        $log.debug("end submitting user to onboarding service")

    view:
      showSteps: $state.current.showSteps
      step: step
      goToNextStep: () ->
        step = $scope.orderSvc.getNextStep($scope.view.step)
        return unless step
        $scope.view.updateState(step)
        $state.go step, $scope.user

      goToPrevStep: () ->
        step = $scope.orderSvc.getPrevStep($scope.view.step)
        $scope.view.updateState(step)
        $state.go step, $scope.user

      updateState:  (step) ->
        proRegEx = /Pro/g
        $scope.view.step = step if step
        $scope.view.hasNextStep = $scope.orderSvc.getNextStep($scope.view.step)?
        $scope.view.hasPrevStep = $scope.orderSvc.getPrevStep($scope.view.step)?
        currentPlan = if $scope.orderSvc.name then $scope.orderSvc.name else 'standard'
        $scope.plan.set(currentPlan)
        $scope.view.currentStepId = $scope.orderSvc.getId($scope.view.step.replace(proRegEx, '')) + 1

    plan:
      name: 'standard'

      getSelected: (planStr) ->
        if $scope.plan.name == planStr then 'selected' else 'select'

      set: (newPlan) ->
        $scope.plan.name = newPlan
        if $scope.view?.plans?
          $scope.plan.price = $scope.view.plans[newPlan]?.price
          unless $scope.plan.price
            $log.error 'invalid plan'

        newPlan

  rmapsOnBoardingOrderSelector.initScope($state, $scope)
  $scope.view.updateState()

app.controller 'rmapsOnBoardingPlanCtrl', ($scope, $state, $log) ->
  $log = $log.spawn("frontend:map:rmapsOnBoardingPlanCtrl")

app.controller 'rmapsOnBoardingPaymentCtrl',
($scope, $state, $log, $document, rmapsStripeService, stripe, rmapsFaCreditCards) ->
  $log = $log.spawn("frontend:map:rmapsOnBoardingPaymentCtrl")

  _safePaymentFields = [
    "amount"
    "last4"
    "brand"
    "country"
    "cvc_check"
    "funding"
    "exp_month"
    "exp_year"
  ]

  _reSubmitOmitFields = _safePaymentFields.slice(0, _safePaymentFields.indexOf "exp_month")

  _cleanReSubmit = () ->
    #we might be resending the card info with user info changes
    #note payment amount must be handled on backend only on actually charging
    $scope.user.card = _.omit $scope.user.card, _reSubmitOmitFields
    delete $scope.user.card.token
    $scope.user.card

  _cleanPayment = (response) ->
    payment = angular.copy($scope.user.card)
    payment = _.omit payment, ["number", "cvc", "exp_month", "exp_year", "amount"]
    payment.token = response.id
    _.extend payment, _.pick response, _safePaymentFields
    payment

  behaveLikeAngularValidation = (formField, rootForm) ->
    fieldIsRequired = formField.$touched && formField.$invalid && !formField.$viewValue
    attemptedSubmital = !rootForm.$pending && !formField.$touched
    $scope.view.submittalClass = if attemptedSubmital then 'has-error' else ''
    fieldIsRequired or attemptedSubmital

  _.merge $scope,
    charge: ->
      stripe.card.createToken(_cleanReSubmit())
      .then (response) ->
        $log.log 'token created for card ending in ', response.card.last4
        _.extend $scope.user, card: _cleanPayment(response)
        $scope.user.card
      .then (safePayment) ->
        $log.debug 'successfully submitted payment to stripe not charged yet'
        $log.debug safePayment
        $scope.user.submit()
      .catch (err) ->
        if err.type and /^Stripe/.test(err.type)
          $log.log 'Stripe error: ', err.message
        else
          $log.log 'Other error occurred, possibly with your API', err.message

    view:
      doShowRequired: behaveLikeAngularValidation
      getCardClass: (typeStr) ->
        return '' unless typeStr
        'fa fa-2x ' +  rmapsFaCreditCards.getCard(typeStr.toLowerCase())

app.controller 'rmapsOnBoardingLocationCtrl', ($scope, $log, rmapsFipsCodes, rmapsUsStates) ->
  $log = $log.spawn("frontend:map:rmapsOnBoardingLocationCtrl")

  $scope.$watch 'user.usStateCode', (usStateCode) ->
    return unless usStateCode

    rmapsFipsCodes.getAllByState usStateCode
    .then (counties) ->
      $scope.counties = counties

  $log.debug $scope

app.controller 'rmapsOnBoardingVerifyCtrl', ($scope, $log) ->
  $log = $log.spawn("frontend:map:rmapsOnBoardingVerifyCtrl")
  $log.debug $scope
