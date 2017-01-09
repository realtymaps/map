# the auth logic in our app expects a subscription plan and status to be one of the following:
# PLAN:
#   NONE - No plan; sub-users / clients with no subscription will have this
#   PRO - Premium plan designed for access to MLS data and county data
#   STANDARD - Standard plan designed for access only to county data
# STATUS:
#   NONE - might occur for sub-users, TODO: should be removed so that plan: NONE would have status: ACTIVE
#   ACTIVE - an account PLAN is fully active, paid, etc
#   TRIALING - a paid user is in the active beginning phase of membership
#   PAST_DUE - a paid user has an invoice that failed (usually would indicate an expired credit card)
#   EXPIRED - a paid user subscription failed or was abandoned (e.g. a credit card failed 3 times and was not replaced)
#   DEACTIVATED - a paid user's subscription was manually ended (cancelation)
#
#
# Other values - helpers or use with stripe API itself:
# PLAN:
#   DEACTIVATED - This constant is applicable in places such as user_subscription.service for talking directly with Stripe.
#                   We represent a DEACTIVATED state for a pro/standard user by setting them up on a 'deactivated' PLAN subscription in Stripe.
#   PAID_LIST - Reference to a list of paid accounts for helping assess general subscriber auth, such as `isSubscriber`
# STATUS:
#   CANCELED - We won't use this often.  When a subscription is canceled, the stripe subscription object `status` will still be `active`,
#              but the object `canceled_at` will represent the time of canceling, and the `current_period_end` will represent the last day of access,
#              which will be end of billing month as a result of `cancel_at_period_end` being true.
#              As a result, when we show a status of 'canceled' on user account page, that technically comes from looking at the 'canceled_at'
#              field instead of the subscription status or this const.  There's no other real need to explicitly read if an account has been canceled, since
#              the user will continue to have "active" level access everywhere.  In the future, if we decide to limit access even before a subscription formally
#              gets deactivated/removed in Stripe, we might have to explicitly save this status on the session (the way we handle other status').
#   ACTIVE_LIST - Reference to a list of account status' that allow full access (depending on plan) for helping assess general
#                 subscriber auth, such as `isSubscriber`

module.exports =
  PLAN:
    PRO: 'pro'
    STANDARD: 'standard'
    NONE: 'none' # subusers, cancelled accounts still active, anyone that can login w/o a subscription
    PAID_LIST: ['pro', 'standard']

    # "deactivated" plan applicable only when communicating with stripe, not representing plan in session
    DEACTIVATED: 'deactivated'

  STATUS:
    NONE: 'none'
    DEACTIVATED: 'deactivated'
    EXPIRED: 'expired' # cancelled accounts that have passed `period_end`

    # https://stripe.com/docs/api#subscription_object-status
    ACTIVE: 'active'
    TRIALING: 'trialing'
    PAST_DUE: 'past_due'
    UNPAID: 'unpaid'
    CANCELED: 'canceled'
    ACTIVE_LIST: ['active', 'trialing', 'past_due']
