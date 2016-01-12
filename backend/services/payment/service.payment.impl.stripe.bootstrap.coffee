Promise = require 'bluebird'
stripeFactory = require 'stripe'
{getAccountInfo} = require '../service.externalAccounts'
{CriticalError} = require '../../utils/errors/util.errors.critical'
{PAYMENT_PLAN} = require '../../config/config'
plansService = require '../service.plans'
{onMissingArgsFail} = require '../../utils/errors/util.errors.args'
exitCodes = require '../../enums/enum.exitCodes'
logger = require '../../config/logger'
_ = require 'lodash'

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
    interval_count: PAYMENT_PLAN.INTERVAL_COUNT
    currency: PAYMENT_PLAN.CURRENCY

  if planName != 'free'
    _.extend plan,
      trial_period_days: PAYMENT_PLAN.TRIAL_PERIOD_DAYS

  stripe.plans.create plan
  .catch (err) ->
    logger.error "CRITICAL ERROR: OUR PAYMENT SYSTEM IS NOT SETUP CORRECTLY"
    logger.error err, true
    if PAYMENT_PLAN.LIVE_MODE
      #TODO: Send EMAIL to dev team
      logger.debug 'email to dev team: initiated'
    process.exit exitCodes.PAYMENT_INIT
  .then (created) ->
    logger.debug "Plan: #{planName} Created"
    created

initializePlan = (stripe, planName, settings) ->
  onMissingArgsFail
    price: {val: settings.price, required: true}
    interval: {val: settings.interval, required: true}

  stripe.plans.retrieve planName
  .then () ->
    logger.debug "Plan: #{planName} already exists"
    #TODO: add updating plan vai differences in metadata
  .catch () ->
    createPlan(stripe, planName, settings)

initializePlans = (stripe) -> Promise.try () ->
  #initialize all plans including aliases to avoid complications
  plansService.getAll().then (plans) ->
    for planName, settings of plans
      initializePlan(stripe, planName, settings)
  #don't wait on plan init kick off rest of api
  stripe

module.exports = do () ->
  getAccountInfo 'stripe'
  .then ({other}) ->
    throw new CriticalError('Stipe API_KEYS intialization failed.') unless other
    API_KEYS = other
    stripeFactory(API_KEYS.secret_test_api_key) #or secret_live_api_key
  .then initializePlans
  .then (stripe) ->
    stripe
