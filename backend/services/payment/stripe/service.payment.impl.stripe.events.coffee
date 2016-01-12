Promise = require 'bluebird'
stripeErrors = require '../../../utils/errors/util.errors.stripe'
{emailPlatform, cancelHash} = require '../../services.email'
userService =  require('../../services.user').user

module.exports = (stripe) ->
  _eventHandles =
    "customer.subscription.created": (subscription, authUser) ->
      #TODO: Send out email notice that their subscription has been created
    "customer.subscription.deleted": (subscription, authUser) ->
      #TODO: Send out email notice that their subscription has been deleted
    "customer.subscription.updated": (subscription, authUser) ->
      #TODO: Send out email notice that their subscription has been updated
    "customer.subscription.trial_will_end": (subscription, authUser) ->
      #TODO: Send out email notice that they will be getting charged via vero
      emailPlatform.then (platform) ->
        platform.trialEnding
          authUser: authUser

  _eventHandles = _.mapValues _eventHandles, (origFunction) ->
    (subscription) -> Promise.try () ->
      userService.getById subscription.customer
      .then (authUser) ->
        origFunction subscription, authUser

  verify = (eventObj) ->
    stripe.events.retrieve eventObj.id

  handle = (eventObj) -> Promise.try () ->
    callEvent = _eventHandles[eventObj.type]
    unless callEvent?
      throw new stripeErrors.StripeInvalidRequest "Invalid Stripe Event, id(#{eventObj.id}) cannot be confirmed"
    verify(eventObj).then (validEvent) ->
      #TODO: this could be moved to validation itself validation.stripe namespace: 'events'
      callEvent(validEvent)

  handle: handle
