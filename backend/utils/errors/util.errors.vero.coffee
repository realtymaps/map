PayloadError = require './util.error.payload.coffee'

class SubscriptionSignUpError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionSignUp', args...)

class SubscriptionCreatedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionCreated', args...)

class SubscriptionVerifiedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionVerified', args...)

class SubscriptionDeletedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionDeleted', args...)

class SubscriptionUpdatedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionUpdated', args...)

class SubscriptionTrialEndedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionTrialEnded', args...)

class CancelPlanError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'CancelPlan', args...)

class NotificationPropertiesSavedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'NotificationPropertiesSaved', args...)

module.exports = {
  SubscriptionSignUpError
  SubscriptionCreatedError
  SubscriptionVerifiedError
  SubscriptionDeletedError
  SubscriptionUpdatedError
  SubscriptionTrialEndedError
  CancelPlanError
  NotificationPropertiesSavedError
}
