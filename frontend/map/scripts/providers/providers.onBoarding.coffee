###global _:true###
app = require '../app.coffee'

app.provider 'rmapsOnBoardingOrder', () ->
  class OnBoardingOrder
    constructor: (@steps = [
      'onBoardingPayment'
      'onBoardingLocation'
    ], @name = '') ->
      @clazz = OnBoardingOrder

    inBounds: (id) ->
      id >= 0 and id < @steps.length

    getStep: (id) ->
      if @inBounds id
        return @steps[id]

    #appends the name of the OnBordingOrder to the current step
    #useful since state name onBoardingPaymentPro -> OnBordingProOrder.onBoardingPayment
    getStepName: (id) =>
      @getStep(id) + @name.toInitCaps()

    getId: (name) ->
      @steps.indexOf name

    getNextStep: (name, direction = 1) ->
      currentId = @getId name
      nextStepId = currentId + direction
      if @inBounds nextStepId
        @getStep nextStepId

    getPrevStep: (name) ->
      @getNextStep name, -1

    $get: ->
      @

  new OnBoardingOrder()

app.provider 'rmapsOnBoardingProOrder', (rmapsOnBoardingOrderProvider) ->
  new rmapsOnBoardingOrderProvider.clazz [
    'onBoardingPayment'
    'onBoardingVerify'
  ], 'pro'

app.provider 'rmapsOnBoardingOrderSelector', (rmapsOnBoardingOrderProvider, rmapsOnBoardingProOrderProvider) ->
  @getPlanFromState = ($state) ->
    if /pro/i.test($state.current.name)
      'pro'

  @getOrderSvc = (plan) =>
    if !_.isString plan
      plan = @getPlanFromState(plan)# then plan should be $state
    if plan == 'pro'
      return rmapsOnBoardingProOrderProvider
    rmapsOnBoardingOrderProvider

  @initScope = (plan, $scope) ->
    $scope.orderSvc = @getOrderSvc(plan)
    $scope.steps = $scope.orderSvc.steps
    $scope

  @$get = =>
    @
  @
