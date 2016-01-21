_ = require 'lodash'
Promise = require 'bluebird'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
backendRoutes = require '../../../../common/config/routes.backend'
{clsFullUrl} = require '../../../utils/util.route.helpers'
logger = require '../../../config/logger'
{EMAIL_PLATFORM} = require '../../../config/config'
{SubscriptionSignUpError
SubscriptionCreatedError
SubscriptionDeletedError
SubscriptionUpdatedError
SubscriptionVerifiedError
SubscriptionTrialEndedError} = require '../../../utils/errors/util.errors.vero'
paymentEvents = require '../../../enums/enum.payment.events'

emailRoutes = backendRoutes.email

inErrorSupportPhrase = """
PS:

If this was not initiated by you or feel this is in error please contact [contact me] (support@realtymaps.com) .
"""

VeroEvents = (vero) ->

  {createOrUpdate} = require('./service.email.impl.vero.user')(vero)

  _requireAuthUser = (opts) -> Promise.try () ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}

  _cancelPlan = (opts) -> Promise.try () ->
    _requireAuthUser(opts)
    {authUser, eventName} = opts
    delete opts.cancelPlanUrl

    cancelPlanUrl = clsFullUrl emailRoutes.cancelPlan.replace(":cancelPlan", authUser.cancel_email_hash)
    createOrUpdate _.extend {}, opts,
      eventName: eventName
      eventData:
        cancel_plan_url: cancelPlanUrl
        in_error_support_phrase: inErrorSupportPhrase

  _callAndRetry = (opts, attempt = 0, ErrorClazz, recallFn, promise) ->
    logger.debug.cyan "#{recallFn.name} ATTEMPT: #{attempt}"

    promise
    .catch (err) ->
      logger.error "#{recallFn.name} error!"
      logger.error err

      if attempt >= EMAIL_PLATFORM.MAX_RETRIES - 1
        logger.error "MAX_RETRIES reached for #{recallFn.name}"
        #add to a JobQueue task to complete later?
        throw new ErrorClazz(opts)

      setTimeout ->
        recallFn opts, attempt++
      , EMAIL_PLATFORM.RETRY_DELAY_MILLI


  # Returns the vero-promise response as Promise([user, event]).
  subscriptionSignUp = (opts, attempt) -> Promise.try () ->
    @name = "subscriptionSignUp"

    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}

    {authUser} = opts

    verifyUrl = clsFullUrl emailRoutes.verify.replace(":hash", authUser.email_validation_hash)

    logger.debug "VERIFY URL"
    logger.debug.yellow verifyUrl

    _callAndRetry opts, attempt, SubscriptionSignUpError, subscriptionSignUp,
      createOrUpdate _.extend {}, opts,
        eventName: paymentEvents.customerSubscriptionCreated
        eventData:
          verify_url: verifyUrl
          in_error_support_phrase: inErrorSupportPhrase


  subscriptionTrialEnding = (opts, attempt) -> Promise.try () ->
    @name = "subscriptionTrialEnding"
    logger.debug "handling vero #{@name}"
    _callAndRetry opts, attempt, SubscriptionTrialEndedError, subscriptionTrialEnding,
      _cancelPlan _.extend {}, opts,
        eventName: paymentEvents.customerSubscriptionTrialWillEnd

  #Purpose To send a Welcome Email stating that the account validation was successful
  subscriptionVerified = (opts, attempt) ->
    @name = "subscriptionVerified"
    logger.debug "handling vero #{@name}"
    _callAndRetry opts, attempt, SubscriptionVerifiedError, subscriptionVerified,
      createOrUpdate _.extend {}, opts,
        eventName: paymentEvents.customerSubscriptionVerified
        eventData:
          in_error_support_phrase: inErrorSupportPhrase

  subscriptionUpdated = (opts, attempt) ->
    @name = "subscriptionUpdated"
    logger.debug "handling vero #{@name}"
    _callAndRetry opts, attempt, SubscriptionUpdatedError, subscriptionUpdated,
      createOrUpdate _.extend {}, opts,
        eventName: paymentEvents.customerSubscriptionUpdated
        eventData:
          in_error_support_phrase: inErrorSupportPhrase

  subscriptionDeleted = (opts, attempt) ->
    @name = "subscriptionDeleted"
    logger.debug "handling vero #{@name}"
    _callAndRetry opts, attempt, SubscriptionDeletedError, subscriptionDeleted,
      createOrUpdate _.extend {}, opts,
        eventName: paymentEvents.customerSubscriptionDeleted
        eventData:
          in_error_support_phrase: inErrorSupportPhrase

  subscriptionSignUp: subscriptionSignUp
  subscriptionVerified: subscriptionVerified
  subscriptionTrialEnding: subscriptionTrialEnding
  subscriptionUpdated: subscriptionUpdated
  subscriptionDeleted: subscriptionDeleted

module.exports = VeroEvents
