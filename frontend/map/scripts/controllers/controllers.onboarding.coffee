###global _:true, angular:true###
app = require '../app.coffee'

app.controller 'rmapsOnBoardingCtrl', ($scope, $state, rmapsOnBoardingOrder, rmapsGeoLocations, rmapsOnBoardingOrderSelector) ->

  rmapsGeoLocations.states().then (states) ->
    $scope.us_states = states

  step = $state.current.name

  $scope.user = {} #constant model for all onBoardingCtrls to use to validate state

  $scope.showSteps = $state.current.showSteps

  $scope.step = step

  rmapsOnBoardingOrderSelector.initScope($state, $scope)

  $scope.goToNextStep = () ->
    step = $scope.orderSvc.getNextStep($scope.step)
    $scope.updateState(step)
    $state.go step

  $scope.goToPrevStep = () ->
    step = $scope.orderSvc.getPrevStep($scope.step)
    $scope.updateState(step)
    $state.go step

  $scope.updateState =  (step) ->
    $scope.step = step if step
    $scope.hasNextStep = $scope.orderSvc.getNextStep($scope.step)?
    $scope.hasPrevStep = $scope.orderSvc.getPrevStep($scope.step)?
    $scope.currentStepId = $scope.orderSvc.getId($scope.step.replace(/Pro/g, '')) + 1

  $scope.updateState()

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
      $scope.updateState step
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

  _.extend $scope,
    showSteps: true
    charge: ->
      stripe.card.createToken($scope.user.card)
      .then (response) ->
        $log.log 'token created for card ending in ', response.card.last4
        userPayment = _.extend {}, $scope.user, card: _cleanPayment(response)
        rmapsStripeService.create(userPayment)
      .then (payment) ->
        $log.log 'successfully submitted payment for $', payment.amount
        payment
        if $scope.hasNextStep
          $scope.goToNextStep()
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

app.controller 'rmapsOnBoardingVerifyCtrl', ($scope) ->
  $log = $log.spawn("map:rmapsOnBoardingVerifyCtrl")
  $log.debug $scope
