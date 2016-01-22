###global _:true###
app = require '../app.coffee'

app.provider 'rmapsOnboardingOrder', () ->
  class OnBoardingOrder
    constructor: (@steps = [
      'onboardingPayment'
      'onboardingLocation'
      'onboardingFinishYay'
    ], @name = '', @submitStepName = 'onboardingLocation') ->
      @clazz = OnBoardingOrder
      @submitStepName += @name.toInitCaps()
      
    inBounds: (id) ->
      id >= 0 and id < @steps.length

    getStep: (id) ->
      if @inBounds id
        return @steps[id]

    #appends the name of the OnBordingOrder to the current step
    #useful since state name onboardingPaymentPro -> OnBordingProOrder.onboardingPayment
    getStepName: (id) =>
      @getStep(id) + @name.toInitCaps()

    getId: (name) =>
      name = name.replace(new RegExp(@name,'ig'),'')
      @steps.indexOf name

    getNextStep: (name, direction = 1) ->
      currentId = @getId name
      nextStepId = currentId + direction
      if @inBounds nextStepId
        @getStepName nextStepId

    getPrevStep: (name) ->
      @getNextStep name, -1

    $get: ->
      @

  new OnBoardingOrder()

app.provider 'rmapsOnboardingProOrder', (rmapsOnboardingOrderProvider) ->
  new rmapsOnboardingOrderProvider.clazz [
    'onboardingPayment'
    'onboardingLocation'
    # 'onboardingVerify'
    'onboardingFinishYay'
  ], 'pro', 'onboardingLocation'#'onboardingVerify'

app.provider 'rmapsOnboardingOrderSelector', (rmapsOnboardingOrderProvider, rmapsOnboardingProOrderProvider) ->
  @getPlanFromState = ($state) ->
    if /pro/i.test($state.current.name)
      'pro'

  @getOrderSvc = (plan) =>
    if !_.isString plan
      plan = @getPlanFromState(plan)# then plan should be $state
    if plan == 'pro'
      return rmapsOnboardingProOrderProvider
    rmapsOnboardingOrderProvider

  @initScope = (plan, $scope) ->
    $scope.orderSvc = @getOrderSvc(plan)
    $scope.view.steps = $scope.orderSvc.steps
    $scope

  @$get = =>
    @
  @
