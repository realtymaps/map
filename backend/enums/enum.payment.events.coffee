Case = require 'case'
_ = require 'lodash'

events = [
  "customer.updated"
  "customer.deleted"
  "customer.subscription.created"
  "customer.subscription.verified" #specific to vero
  "customer.subscription.deleted"
  "customer.subscription.updated"
  "customer.subscription.trial_will_end"
]

module.exports = _.indexBy events, (val) ->
  Case.camel(val)
