Promise = require 'bluebird'
_ = require 'lodash'
stripeErrors = require '../../../utils/errors/util.errors.stripe'
{emailPlatform} = require '../../services.email'
tables = require '../../../config/tables'
dbs = require '../../../config/dbs'
db = dbs.get('main')
{expectSingleRow} = require '../../../utils/util.sql.helpers'
{customerSubscriptionCreated
customerSubscriptionDeleted
customerSubscriptionUpdated
customerSubscriptionTrialWillEnd} = require '../../../enums/enum.payment.events'
logger = require('../../../config/logger').spawn('stripe')


emailPlatform.then (platform) ->
  emailPlatform = platform

StripeEvents = (stripe) ->
  _eventHandles = {}
  _eventHandles['default'] = (subscription, authUser) ->
    logger.debug "default stripe webhook event handling"

  _eventHandles[customerSubscriptionCreated] = (subscription, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionCreated}"
    emailPlatform.events.subscriptionVerified
      authUser: authUser
      plan: subscription.data.object.plan.name

  _eventHandles[customerSubscriptionDeleted] = (subscription, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionDeleted}"
    emailPlatform.events.subscriptionDeleted
      authUser: authUser
      plan: subscription.data.object.plan.name

  _eventHandles[customerSubscriptionUpdated] = (subscription, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionUpdated}"
    emailPlatform.events.subscriptionUpdated
      authUser: authUser
      plan: subscription.data.object.plan.name

  _eventHandles[customerSubscriptionTrialWillEnd] = (subscription, authUser) ->
    logger.debug "stripe handling #{customerSubscriptionTrialWillEnd}"
    emailPlatform.events.subscriptionTrialEnding
      authUser: authUser
      plan: subscription.data.object.plan.name

  _eventHandles = _.mapValues _eventHandles, (origFunction) ->
    (subscription) -> Promise.try () ->
      {customer} = subscription.data.object
      logger.debug "Attempting to get auth_user that has a stipe customer id of #{customer}"
      unless customer
        logger.debug subscription, true

      q = tables.auth.user().where(stripe_customer_id: customer)
      # logger.debug q.toString()

      q.then (results) ->
        expectSingleRow(results)
      .then (authUser) ->
        origFunction subscription, authUser

  _verify = (eventObj) ->
    logger.debug "_verify"
    stripe.events.retrieve eventObj.id

  handle = (eventObj) -> Promise.try () ->
    callEvent = _eventHandles[eventObj.type] or _eventHandles['default']

    _verify(eventObj)
    .then (validEvent) ->

      # log the event in event history
      tables.event.history()
      .insert(
        auth_user_id: tables.auth.user().select('id').where(stripe_customer_id: validEvent.data.object.customer)
        event_type: validEvent.type
        data_blob: validEvent
      ).then () ->
        logger.debug "Event successfully inserted into history table."
        logger.debug "POST _verify"
        logger.debug "calling #{eventObj.type}"
        logger.debug _eventHandles, true

        callEvent(validEvent)
      .catch (err) ->
        throw new stripeErrors.StripeEventHandlingError err, "Error while logging & handling stripe webhook event."

  handle: handle

module.exports = StripeEvents
