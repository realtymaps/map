generators = require './impl/util.error.impl.generators'

module.exports = generators.payload [
  'SubscriptionSignUp'
  'SubscriptionCreated'
  'SubscriptionVerified'
  'SubscriptionDeleted'
  'SubscriptionUpdated'
  'SubscriptionTrialEnded'
  'CancelPlan'
  'Critical'
  'InitCritical'
]
