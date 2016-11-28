stripeFactory = require 'stripe'
externalAccounts = require '../../service.externalAccounts'
{CriticalError} = require '../../../utils/errors/util.errors.critical'
config = require '../../../config/config'
plansService = require '../../service.plans'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
logger = require('../../../config/logger').spawn('stripe')
shutdown = require '../../../config/shutdown'
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
    interval_count: config.PAYMENT_PLATFORM.INTERVAL_COUNT
    currency: config.PAYMENT_PLATFORM.CURRENCY

  if planName != 'free'
    _.extend plan,
      trial_period_days: config.PAYMENT_PLATFORM.TRIAL_PERIOD_DAYS

  stripe.plans.create plan
  .catch (err) ->
    logger.error "CRITICAL ERROR: OUR PAYMENT PLATFORM IS NOT SETUP CORRECTLY"
    logger.error err, true
    if config.PAYMENT_PLATFORM.LIVE_MODE
      #TODO: Send EMAIL to dev team
      logger.debug 'email to dev team: initiated'
    shutdown.exit(error: true)
  .then (created) ->
    logger.debug "Plan: #{planName} Created"
    created

initializePlan = (stripe, planName, settings) ->
  try
    logger.debug "Attempting to initialize plan: #{planName}"
    onMissingArgsFail args: settings, required: ['price', 'interval']
  catch error
    logger.error error
    shutdown.exit(error: true)

  stripe.plans.retrieve planName
  .then () ->
    logger.debug "Plan: #{planName} already exists"
    #TODO: add updating plan via differences in metadata
  .catch (err) ->
    # Sometimes ECONNRESET / StripConnectionError occurs here which halts the app. In dev can this be avoided?
    logger.debug err
    createPlan(stripe, planName, settings)

initializePlans = (stripe) ->
  #initialize all plans including aliases to avoid complications
  plansService.getAll().then (plans) ->
    for planName, settings of plans
      initializePlan(stripe, planName, settings)
  #don't wait on plan init kick off rest of api
  stripe


module.exports = do ->
  externalAccounts.getAccountInfo('stripe')
  .then ({other}) ->
    throw new CriticalError('Stripe API_KEYS intialization failed.') unless other
    API_KEYS = other
    if config.PAYMENT_PLATFORM.LIVE_MODE
      if config.ENV != 'production' && !config.ALLOW_LIVE_APIS
        throw new Error("Refusing to use stripe live API from #{config.ENV} -- set ALLOW_LIVE_APIS to force")
      apiKeyNameStr = 'live'
    else
      apiKeyNameStr = 'test'

    keyToUse = "secret_#{apiKeyNameStr}_api_key"
    logger.debug "using API_KEY prop: #{keyToUse} for backend stripe"
    secret_api_key = API_KEYS[keyToUse]
    stripeFactory(secret_api_key)
  .then initializePlans
  .then (stripe) ->
    stripe
