###global _:true###
app = require '../app.coffee'

#TODO: see if using $state.is via siblings is a way of avoiding providers.onboarding
app.controller 'rmapsOnboardingCtrl', (
$q,
$log,
$scope,
$state,
$stateParams,
rmapsOnboardingOrderService,
rmapsOnboardingOrderSelectorService,
rmapsPlansService,
rmapsOnboardingService,
rmapsUsStates
) ->

  $log = $log.spawn("frontned:map:rmapsOnboardingCtrl")

  $scope.us_states = rmapsUsStates.all

  rmapsPlansService.getList().then (plans) ->
    _.merge $scope,
      view:
        plans: plans

  step = $state.current.name

  _.merge $scope, user: $stateParams or {},
    user: #constant model passed through all states
      passwordChange: ->
        if @password != @confirmPassword
          @errorMsg = 'passwords do not match!'
        else
          delete @errorMsg
      plan:
        name: 'standard'

        getSelected: (planStr) ->
          if $scope.user.plan.name == planStr then 'selected' else 'select'

        set: (newPlan) ->
          $scope.user.plan.name = newPlan
          rmapsOnboardingOrderSelectorService.initScope(newPlan, $scope)
          if $scope.view?.plans?
            $scope.user.plan.price = $scope.view.plans[newPlan]?.price
            unless $scope.user.plan.price
              $log.error 'invalid plan'

          newPlan

      submit: () ->
        $scope.view.showSteps = true
        promise = $q.resolve()
        if $scope.orderSvc.submitStepName == step
          $log.debug("begin submitting user to onboarding service")
          $log.debug($scope.user)
          $log.debug("end submitting user to onboarding service")
          promise = rmapsOnboardingService.user.create($scope.user)

        promise.then () ->
          if $scope.view.hasNextStep
            return $scope.view.goToNextStep()

    view:
      showSteps: $state.current.showSteps
      step: step
      goToNextStep: () ->
        step = $scope.orderSvc.getNextStep($scope.view.step)
        unless step
          $log.error("step undefined")
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
        aPlan = $scope.orderSvc.name or $scope.user.plan.name
        currentPlan = aPlan or 'standard'
        $scope.user.plan.set(currentPlan)
        $scope.view.currentStepId = $scope.orderSvc.getId($scope.view.step.replace(proRegEx, '')) + 1

  $log.debug "current user data"
  $log.debug $scope.user

  rmapsOnboardingOrderSelectorService.initScope($state, $scope)
  $scope.view.updateState()

app.controller 'rmapsOnboardingPlanCtrl', ($scope, $state, $log) ->
  $log = $log.spawn("map:rmapsOnboardingPlanCtrl")

app.controller 'rmapsOnboardingPaymentCtrl',
($scope, $state, $log, $document, stripe, rmapsFaCreditCardsService) ->
  $log = $log.spawn("map:rmapsOnboardingPaymentCtrl")

  _safePaymentFields = [
    "id"
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

  _cleanToken = (token) ->
    token.card = _.omit token.card, ["number", "cvc", "exp_month", "exp_year", "amount"]
    token

  behaveLikeAngularValidation = (formField, rootForm) ->
    fieldIsRequired = formField.$touched && formField.$invalid && !formField.$viewValue
    attemptedSubmital = !rootForm.$pending && !formField.$touched
    $scope.view.submittalClass = if attemptedSubmital then 'has-error' else ''
    fieldIsRequired or attemptedSubmital

  _.merge $scope,
    charge: ->
      stripe.card.createToken(_cleanReSubmit())
      .then (token) ->
        $log.debug 'token created for card ending in ', token.card.last4
        _.extend $scope.user, token: _cleanToken(token)
        $scope.user.card
      .then (safePayment) ->
        $log.debug 'successfully submitted payment to stripe not charged yet'
        $log.debug safePayment
        $scope.user.submit()
      .catch (err) ->
        if err.type and /^Stripe/.test(err.type)
          $log.error 'Stripe error: ', err.message
        else
          $log.error 'Other error occurred, possibly with your API', err.message

    view:
      doShowRequired: behaveLikeAngularValidation
      getCardClass: (typeStr) ->
        return '' unless typeStr
        'fa fa-2x ' +  rmapsFaCreditCardsService.getCard(typeStr.toLowerCase())

app.controller 'rmapsOnboardingLocationCtrl', ($scope, $log, rmapsFipsCodesService, rmapsMlsService) ->
  $log = $log.spawn("map:rmapsOnboardingLocationCtrl")

  $scope.supportedMLS =
    show: true
    change: () ->
      delete $scope.user.mls_code

  $scope.doneButton =
    getText:  () ->
      if !$scope.supportedMLS.show
        'Procceed Unsupported'
      else
        'Done'

    getTitle: () ->
      if !$scope.supportedMLS.show
        'You are proceeding as a standard account with the chance of pro.'
      else
        'Done'


  $scope.$watch 'user.us_state_code', (usStateCode) ->
    return unless usStateCode

    rmapsFipsCodesService.getAllMlsCodes state: usStateCode
    .then (fipsCodes) ->
      $scope.counties = fipsCodes

    rmapsFipsCodesService.getAllSupportedMlsCodes state: usStateCode
    .then (mlsFipsCounties) ->
      $scope.mlsFipsCounties = mlsFipsCounties

    rmapsMlsService.getAll state: usStateCode
    .then (mlses) ->
      $scope.mlsCodes = mlses

    rmapsMlsService.getAllSupported state: usStateCode
    .then (mlses) ->
      $scope.supportedMlsCodes = mlses


  $log.debug $scope

app.controller 'rmapsOnboardingVerifyCtrl', ($scope, $log) ->
  $log = $log.spawn("map:rmapsOnboardingVerifyCtrl")
  $log.debug $scope

app.controller 'rmapsOnboardingFinishYayCtrl', ($scope, $log, $state, $timeout, rmapsLoginFactory) ->
  $log = $log.spawn("map:rmapsOnboardingFinishYayCtrl")
  $scope.view.showSteps = false

  rmapsLoginFactory($scope)

  if !$scope.user.email?
    return

  $timeout () ->
    $scope.doLogin($scope.user)
  , 2000
