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

class SubscriptionUpdatedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionUpdated', args...)

class SubscriptionTrialEndedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionTrialEnded', args...)

class SubscriptionDeactivatedError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionDeleted', args...)

class SubscriptionExpiredError extends PayloadError
  constructor: (payload, args...) ->
    super(payload, 'SubscriptionDeleted', args...)

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
  SubscriptionUpdatedError
  SubscriptionTrialEndedError
  SubscriptionDeactivatedError
  SubscriptionExpiredError
  CancelPlanError
  NotificationPropertiesSavedError
}
