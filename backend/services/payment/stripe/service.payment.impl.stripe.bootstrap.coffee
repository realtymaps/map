stripeFactory = require 'stripe'
{getAccountInfo} = require '../../service.externalAccounts'
{CriticalError} = require '../../../utils/errors/util.errors.critical'
{PAYMENT_PLATFORM} = require '../../../config/config'
plansService = require '../../service.plans'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
exitCodes = require '../../../enums/enum.exitCodes'
logger = require('../../../config/logger').spawn('stripe')
_ = require 'lodash'

#StripeBootstrap

dollarsToCents = (dollars) ->
  dollars * 100

createPlan = (stripe, planName, settings) ->
  logger.debug "Creating Plan: #{planName}"

  plan =
    id: planName
    amount: dollarsToCents settings.price
    interval: settings.interval
    metadata: settings
    name: planName
    interval_count: PAYMENT_PLATFORM.INTERVAL_COUNT
    currency: PAYMENT_PLATFORM.CURRENCY

  if planName != 'free'
    _.extend plan,
      trial_period_days: PAYMENT_PLATFORM.TRIAL_PERIOD_DAYS

  stripe.plans.create plan
  .catch (err) ->
    logger.error "CRITICAL ERROR: OUR PAYMENT PLATFORM IS NOT SETUP CORRECTLY"
    logger.error err, true
    if PAYMENT_PLATFORM.LIVE_MODE
      #TODO: Send EMAIL to dev team
      logger.debug 'email to dev team: initiated'
    process.exit exitCodes.PAYMENT_INIT
  .then (created) ->
    logger.debug "Plan: #{planName} Created"
    created

initializePlan = (stripe, planName, settings) ->
  try
    logger.debug "Attempting to initialize plan: #{planName}"
    onMissingArgsFail args: settings, required: ['price', 'interval']
  catch error
    logger.error error
    process.exit exitCodes.PAYMENT_INIT

  stripe.plans.retrieve planName
  .then () ->
    logger.debug "Plan: #{planName} already exists"
    #TODO: add updating plan vai differences in metadata
  .catch () ->
    createPlan(stripe, planName, settings)

initializePlans = (stripe) ->
  #initialize all plans including aliases to avoid complications
  plansService.getAll().then (plans) ->
    for planName, settings of plans
      initializePlan(stripe, planName, settings)
  #don't wait on plan init kick off rest of api
  stripe

module.exports = do ->
  promise = if process.env.CIRCLECI then Promise.resolve(
    other:
      secret_test_api_key: ''
      secret_live_api_key: ''
    ) else getAccountInfo 'stripe'

  promise.then ({other}) ->
    throw new CriticalError('Stipe API_KEYS intialization failed.') unless other
    API_KEYS = other
    apiKeyNameStr = if PAYMENT_PLATFORM.LIVE_MODE then 'live' else 'test'
    keyToUse = "secret_#{apiKeyNameStr}_api_key"
    logger.debug "using API_KEY prop: #{keyToUse} for backend stripe"
    secret_api_key = API_KEYS[keyToUse]
    stripeFactory(secret_api_key)
  .then initializePlans
  .then (stripe) ->
    stripe
