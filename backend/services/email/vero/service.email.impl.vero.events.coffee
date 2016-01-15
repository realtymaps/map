_ = require 'lodash'
Promise = require 'bluebird'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
backendRoutes = require '../../../../common/config/routes.backend'
{clsFullUrl} = require '../../../utils/util.route.helpers'
logger = require '../../../config/logger'
{EMAIL_PLATFORM} = require '../../../config/config'
{SignUpError} = require '../../../utils/errors/util.errors.vero'

emailRoutes = backendRoutes.email

# makeVeroEvent = (stripeEvent) ->
#   stripeEvent.toInitCaps()
#   .replace(/\./g, ' ').replace(/_/g, ' ')

trialEndingEvent = 'customer.subscription.trial_will_end'
customerCreatedEvent = 'customer.subscription.created'


VeroEvents = (vero) ->

  {createOrUpdate} = require('./service.email.impl.vero.user')(vero)

  # Returns the vero-promise response as Promise([user, event]).
  signUp = (opts, attempt = 0) -> Promise.try () ->
    logger.debug.cyan "SIGNUP ATTEMPT: #{attempt}"
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}

    {authUser} = opts

    verifyUrl = clsFullUrl emailRoutes.verify.replace(":hash", authUser.email_validation_hash)

    logger.debug "VERIFY URL"
    logger.debug.yellow verifyUrl

    createOrUpdate _.extend {}, opts,
      eventName: customerCreatedEvent
      eventData: verify_url: verifyUrl
    .catch (err) ->
      logger.error "signUp error!"
      logger.error err

      if attempt >= EMAIL_PLATFORM.MAX_RETRIES - 1
        logger.error "MAX_RETRIES reached for signUp for new user"
        throw new SignUpError(opts)

      setTimeout ->
        signUp opts, attempt++, err
      , EMAIL_PLATFORM.RETRY_DELAY_MILLI

  _cancelPlan = (opts) -> Promise.try () ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}

    {authUser, eventName} = opts
    delete opts.cancelPlanUrl

    createOrUpdate _.extend {}, opts,
      eventName: eventName
        eventData: cancel_plan_url: authUser.cancel_email_hash

  trialEnding = (opts) -> Promise.try () ->
    _cancelPlan _.extend {}, opts, eventName: trialEndingEvent

  signUp: signUp
  trialEnding: trialEnding
  # makeVeroEvent: makeVeroEvent

module.exports = VeroEvents
