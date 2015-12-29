###global _:true, angular:true###
app = require '../app.coffee'

app.controller 'rmapsOnBoardingCtrl', ($scope, $state, $stateParams, rmapsOnBoardingOrder, rmapsGeoLocations, rmapsOnBoardingOrderSelector) ->

  rmapsGeoLocations.states().then (states) ->
    $scope.us_states = states

  step = $state.current.name

  _.merge $scope,
    user: {} #constant model for all onBoardingCtrls to use to validate state
    view:
      showSteps: $state.current.showSteps
      step: step
      goToNextStep: () ->
        step = $scope.orderSvc.getNextStep($scope.view.step)
        $scope.view.updateState(step)
        $state.go step
      goToPrevStep: () ->
        step = $scope.orderSvc.getPrevStep($scope.view.step)
        $scope.view.updateState(step)
        $state.go step

      updateState:  (step) ->
        $scope.view.step = step if step
        $scope.view.hasNextStep = $scope.orderSvc.getNextStep($scope.view.step)?
        $scope.view.hasPrevStep = $scope.orderSvc.getPrevStep($scope.view.step)?
        $scope.view.currentStepId = $scope.orderSvc.getId($scope.view.step.replace(/Pro/g, '')) + 1

  rmapsOnBoardingOrderSelector.initScope($state, $scope)
  $scope.view.updateState()

app.controller 'rmapsOnBoardingPlanCtrl', ($scope, $state, $log, rmapsOnBoardingOrderSelector) ->
  $log = $log.spawn("map:rmapsOnBoardingPlanCtrl")

  $scope.plan = 'standard'

  $scope.getSelected = (planStr) ->
    if $scope.plan == planStr then 'selected' else 'select'

  $scope.setPlan = (newPlan) ->
    $scope.plan = newPlan

  _.extend $scope.user,
    submit: () ->
      svc = rmapsOnBoardingOrderSelector.getOrderSvc($scope.plan)
      $log.debug svc.name + ' selected'
      step = svc.getStepName(0)
      $scope.view.updateState step
      $scope.view.showSteps = true
      $state.go step

app.controller 'rmapsOnBoardingPaymentCtrl',
($scope, $state, $log, $document, rmapsStripeService, stripe, rmapsFaCreditCards) ->
  $log = $log.spawn("map:rmapsOnBoardingPaymentCtrl")

  _cleanPayment = (response) ->
    payment = angular.copy($scope.user.card)
    delete payment.number
    delete payment.cvc
    delete payment.exp_month
    delete payment.exp_year
    payment.token = response.id
    payment

  behaveLikeAngularValidation = (formField, rootForm) ->
    fieldIsRequired = formField.$touched && formField.$invalid && !formField.$viewValue
    attemptedSubmital = !rootForm.$pending && !formField.$touched
    $scope.view.submittalClass = if attemptedSubmital then 'has-error' else ''
    fieldIsRequired or attemptedSubmital

  _.merge $scope,
    charge: ->
      stripe.card.createToken($scope.user.card)
      .then (response) ->
        $log.log 'token created for card ending in ', response.card.last4
        userPayment = _.extend {}, $scope.user, card: _cleanPayment(response)
        rmapsStripeService.create(userPayment)
      .then (payment) ->
        $log.log 'successfully submitted payment for $', payment.amount
        payment
        if $scope.view.hasNextStep
          $scope.view.goToNextStep()
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

app.controller 'rmapsOnBoardingLocationCtrl', ($scope, $log) ->
  $log = $log.spawn("map:rmapsOnBoardingLocationCtrl")
  $log.debug $scope

app.controller 'rmapsOnBoardingVerifyCtrl', ($scope, $log) ->
  $log = $log.spawn("map:rmapsOnBoardingVerifyCtrl")
  $log.debug $scope
