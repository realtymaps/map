Promise = require 'bluebird'
_ = require 'lodash'
stripeErrors = require '../../../utils/errors/util.errors.stripe'
{emailPlatform} = require '../../services.email'
userTable = require('../../../config/tables').auth.user
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

      q = userTable().where(stripe_customer_id: customer)
      # logger.debug q.toString()

      q.then expectSingleRow
      .then (authUser) ->
        origFunction subscription, authUser

  _verify = (eventObj) ->
    logger.debug "_verify"
    stripe.events.retrieve eventObj.id

  handle = (eventObj) -> Promise.try () ->
    callEvent = _eventHandles[eventObj.type]
    unless callEvent?
      throw new stripeErrors.StripeInvalidRequest "Invalid Stripe Event, id(#{eventObj.id}) cannot be confirmed"
    _verify(eventObj).then (validEvent) ->
      logger.debug "POST _verify"
      logger.debug "calling #{eventObj.type}"
      logger.debug _eventHandles, true

      callEvent(validEvent)
      .catch (err) ->
        #TODO: maybe rethink this
        #We need stripe to move on as an account might have been deleted
        logger.error "Swallowing Error"
        logger.error err?.message

  handle: handle

module.exports = StripeEvents
