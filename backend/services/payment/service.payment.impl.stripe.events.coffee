Promise = require 'bluebird'
stripeErrors = require '../../utils/errors/util.errors.stripe'

module.exports = (stripe) ->
  _eventHandles =
    "customer.subscription.created": (validBody) ->
      #TODO: Send out email notice that their subscription has been created
    "customer.subscription.deleted": (validBody) ->
      #TODO: Send out email notice that their subscription has been deleted
    "customer.subscription.updated": (validBody) ->
      #TODO: Send out email notice that their subscription has been updated
    "customer.subscription.trial_will_end": (validBody) ->
      #TODO: Send out email notice that they will be getting charged via vero

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
