Promise = require 'bluebird'
stripeErrors = require '../../../utils/errors/util.errors.stripe'
{PartiallyHandledError} = require '../../../utils/errors/util.error.partiallyHandledError'
emailSvc = require '../../services.email'
tables = require '../../../config/tables'
dbs = require '../../../config/dbs'
subscriptionSvc = require '../../service.user_subscription'
{expectSingleRow} = require '../../../utils/util.sql.helpers'
{customerSubscriptionCreated
customerSubscriptionDeleted
customerSubscriptionUpdated
customerSubscriptionTrialWillEnd} = require '../../../enums/enum.vero.events'
logger = require('../../../config/logger').spawn('stripe')


emailPlatform = null
# ('../../services.email').emailPlatform is same as '../../email/vero' (bootstrapped `events` and `vero`)
emailSvc.emailPlatform.then (platform) -> emailPlatform = platform

StripeEvents = (stripe) ->
  _eventHandles = {}
  _eventHandles['default'] = (eventObj, authUser) ->
    logger.debug "default stripe webhook event handling"

  _eventHandles[customerSubscriptionCreated] = (eventObj, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionCreated}"
    emailPlatform.events.subscriptionVerified(authUser)

  _eventHandles[customerSubscriptionDeleted] = (eventObj, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionDeleted}"

    # Check status of deleted / canceled subscription.
    # NOTE: this status that stripe sets for an failed payment subscr is controlled in the stripe dashboard
    #   (it should be configured to set a failed subscription status to "unpaid", which means an expired subscr for us)
    Promise.try () ->
      if eventObj.data.object.status == 'unpaid'
        emailPlatform.events.subscriptionExpired(authUser).then () ->
          stripe.customers.retrieve authUser.stripe_customer_id
          .then (customer) ->
            stripe.customers.deleteCard(customer.id, customer.default_source)

      else
        subscriptionSvc.deactivatePlan(authUser)
        .then (res) ->
          logger.debug "User #{authUser.id} set on deactivated subscription in stripe."
          emailPlatform.events.subscriptionDeactivated(authUser)

    # deactivate any projects this user owned
    # promise
    .then () ->
      tables.user.project()
      .update status: 'inactive'
      .where auth_user_id: authUser.id

    # clean/end session (forces relog)
    .then () ->
      tables.auth.session()
      .whereIn 'sid', () ->
        @select('session_id')
        .from tables.auth.sessionSecurity.tableName
        .where user_id: authUser.id
      .del()
      .then () ->
        tables.auth.sessionSecurity()
        .where user_id: authUser.id
        .del()


  _eventHandles[customerSubscriptionUpdated] = (eventObj, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionUpdated}"
    emailPlatform.events.subscriptionUpdated(authUser)

  _eventHandles[customerSubscriptionTrialWillEnd] = (eventObj, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionTrialWillEnd}"
    emailPlatform.events.subscriptionTrialEnding(authUser)


  _getAuthUser = (eventObj, transaction) ->
    customer = eventObj.data.object.customer
    logger.debug "Attempting to get auth_user that has a stipe customer id of #{customer}"

    if !customer
      logger.warn -> "Customer reference not found in event object:\n#{JSON.stringify(eventObj)}"

    tables.auth.user({transaction}).where(stripe_customer_id: customer)
    .then (results) ->
      expectSingleRow(results)


  _verify = (eventObj) ->
    logger.debug "_verify"
    stripe.events.retrieve(eventObj.id)
    .catch stripeErrors.StripeInvalidRequestError, (err) ->
      return null


  handle = (eventObj) -> Promise.try () ->
    dbs.transaction 'main', (transaction) ->
      _verify(eventObj)
      .then (validEvent) ->
        if !validEvent?
          throw new PartiallyHandledError("Stripe webhook event invalid -  id:#{eventObj.id}, type:#{eventObj.type}")
        _getAuthUser(validEvent, transaction)
        .then (authUser) ->
          if authUser?

            callEvent = _eventHandles[validEvent.type] or _eventHandles['default']

            # log the event in event history
            tables.history.event({transaction})
            .insert(
              auth_user_id: authUser.id
              event_type: validEvent.type
              data_blob: validEvent
            ).then () ->
              logger.debug "Event successfully inserted into history table."
              logger.debug "POST _verify"
              logger.debug "calling #{validEvent.type}"
              logger.debug _eventHandles, true

              callEvent(validEvent, authUser)
            .catch (err) ->
              throw new stripeErrors.StripeEventHandlingError err, "Error while logging & handling stripe webhook event."

  handle: handle

module.exports = StripeEvents
