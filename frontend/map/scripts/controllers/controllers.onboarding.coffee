###global _:true###
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
    $state.go step if step

  $scope.goToPrevStep = () ->
    step = $scope.orderSvc.getPrevStep($scope.step)
    $state.go step if step

  $scope.hasNextStep = () ->
    $scope.orderSvc.getNextStep($scope.step)?

  $scope.hasPrevStep = () ->
    $scope.orderSvc.getPrevStep($scope.step)?

  $scope.currentStepId = () ->
    $scope.orderSvc.getId($scope.step.replace(/Pro/g, '')) + 1

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
      $state.go svc.getStepName(0)

app.controller 'rmapsOnBoardingPaymentCtrl', ($scope) ->
app.controller 'rmapsOnBoardingLocationCtrl', ($scope) ->
app.controller 'rmapsOnBoardingVerifyCtrl', ($scope) ->
