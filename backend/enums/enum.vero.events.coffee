Case = require 'case'
_ = require 'lodash'

###
Vero Events

Note the vero system is a mess in how events are traced via it's UI/UX with the following
inconsistencies:

- Campaigns View: All spaces and periods will be displayed as UNDERSCORE in the
  Campaign View of Newletters, Behavioral, and Transactions.

  Example:
  "customer.subscription.created" -> "customer_subscription_created"

- New Campaign View: All underscores and periods will displayed as spaces.
  Also the first letter will be capitalized.

  Example:
  "customer.subscription.created" -> "Customer subscription created"
  "customer_subscription_created" -> "Customer subscription created"


Now just because the Vero UI is a mess does not mean we should be a mess. We need to stick with
with either periods or underscores and choose one way forward.

Besides here (this file) the only source of truth on what an event name actually is, is in the logs of vero.
https://app.getvero.com/logs

IMPORTANT:

The below list should be kept in sync with what events are in the vero system. This way we can easily
tell what the actual named events are in vero to limit the confusion.

Lastly old events can not be renamed or deleted. Therefore creating "customer_subscription_created" to copy/replace
"customer.subscription.created" would result in a duplicate drop down selection of "Customer subscription created". Therefore
it is suggested here that we leave the events we have alone and stay consistent with a chosen format.
###

events = [
  "customer.updated"
  "customer.deleted"
  "customer.subscription.created"
  "customer.subscription.verified" #specific to vero
  "customer.subscription.deleted"
  "customer.subscription.updated"
  "customer.subscription.trial_will_end"
  #NOTE UNDERSCORES ARE THE WAY FORWARD
  # if switch the above to periods to underscores in vero then we will have duplicates in the New Campaign view.
  "subscription_deactivated"
  "subscription_expired"
  "notification_properties_saved"
  "client_created"
  "client_invited"
]

module.exports = _.indexBy events, (val) ->
  Case.camel(val)
