config = require '../config/config'
Promise = require 'bluebird'
tables = require '../config/tables'
dbs = require '../config/dbs'
permSvc = require './service.permissions'
{expectSingleRow} = require '../utils/util.sql.helpers'
# sqlColumns = require '../utils/util.sql.columns'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
stripeErrors = require '../utils/errors/util.errors.stripe'

# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("service.user_subscription")
stripe = null
veroSvc = null
require('../services/payment/stripe')().then (svc) -> stripe = svc.stripe
require('./email/vero').then (svc) -> veroSvc = svc
# coffeelint: enable=check_scope


# Return "dummy" subscription objects that emulates a stripe subscription
# For use when canceled subscription data is no longer available from stripe
expiredSubscription = (planId) ->
  status: config.SUBSCR.STATUS.EXPIRED
  plan:
    id: planId


_getStripeSubscription = (stripe_customer_id, stripe_subscription_id, stripe_plan_id) -> Promise.try () ->
  if !stripe_subscription_id?
    if stripe_plan_id?
      return expiredSubscription(stripe_plan_id)
    return null

  stripe.customers.retrieveSubscription stripe_customer_id, stripe_subscription_id
  .then (subscription) ->
    return subscription

  # If the subscription was canceled, stripe deletes the subscription upon period_end.
  # In this scenario, we want to relay the subscription has EXPIRED and remove the id.
  # Ideally, we will have gotten a webhook event to let us know to remove it.
  .catch stripeErrors.StripeInvalidRequestError, (err) ->

    # nullify subscription_id so we know its expired
    tables.auth.user()
    .update stripe_subscription_id: null
    .where {stripe_customer_id}
    .then () ->

      if stripe_plan_id? # defensive; we would expect a plan_id if there existed a subscription_id
        return expiredSubscription(stripe_plan_id)
      else
        throw new PartiallyHandledError("No subscription or plan is associated with user #{stripe_customer_id}.")


_getStripeIds = (userId, transaction) ->
  tables.auth.user({transaction})
  .select 'stripe_customer_id', 'stripe_subscription_id', 'stripe_plan_id'
  .where id: userId
  .then (result) ->
    expectSingleRow result
  .then (ids) ->
    ids


# update plan among paid subscription levels
updatePlan = (userId, plan) ->
  if !(plan in config.SUBSCR.PLAN.PAID_LIST)
    throw new PartiallyHandledError("Cannot upgrade to plan #{plan} because it is invalid.")

  getSubscription(userId)
  .then (res) ->

    # defensive checks, just return the subscription if it's the same plan as needing set
    if res.plan?.id == plan
      return {
        status: res.status
        updated: res
      }

    stripe.subscriptions.update(res.id, {plan, trial_end:'now'}) # ensure not to re-add trial period added just for switching plans
    .then (updated) ->
      newPlan =
        stripe_subscription_id: updated.id
        stripe_plan_id: plan

      tables.auth.user()
      .update newPlan
      .where id: userId
      .then () ->
        status: updated.status
        updated: updated


# When a subscription reaches the end date, Stripe sends webhook request that triggers this routine
deactivatePlan = (authUser) ->
  payload =
    customer: authUser.stripe_customer_id
    plan: config.SUBSCR.PLAN.DEACTIVATED
    trial_end: 'now' # no trial period on deactivation

  stripe.subscriptions.create(payload)
  .then (deactivated) ->
    tables.auth.user()
    .update stripe_subscription_id: deactivated.id
    .where id: authUser.id
    .then () ->
      deactivated


# determine plan and return a status to use on user & session for part of subscription level access
getStatus = (user) -> Promise.try () ->
  obj =
    subscriptionPlan: config.SUBSCR.PLAN.NONE
    subscriptionStatus: config.SUBSCR.STATUS.NONE

  # stripe_customer or stripe_subscr may not exist for staff, client subusers, etc...
  if !user.stripe_customer_id? && !user.stripe_subscription_id? # if no customer or subscription exists...

    # check internal permissions (special case stuff like for superuser or staff is handled there)...
    permSvc.getPermissionsForUserId user.id
    .then (results) ->
      # return subscription level for the staff if granted a perm for it
      if results.access_premium
        obj.subscriptionPlan = config.SUBSCR.PLAN.PRO
        obj.subscriptionStatus = config.SUBSCR.STATUS.ACTIVE

      else if results.access_standard
        obj.subscriptionPlan = config.SUBSCR.PLAN.STANDARD
        obj.subscriptionStatus = config.SUBSCR.STATUS.ACTIVE

      return obj

  # a customer with a stripe_plan_id implies we either have or had a subscription, so try to get it...
  else if user.stripe_plan_id? # a stripe subscription exists, retrieve status
    _getStripeSubscription user.stripe_customer_id, user.stripe_subscription_id, user.stripe_plan_id
    .then (subscription) ->
      obj.subscriptionPlan = user.stripe_plan_id

      # To make it easier to represent plan and status even when deactivated, we translate the stripe deactivated plan id into
      #   a status of the users own paid account
      #   i.e. we want it to be like {plan: 'pro', status: 'deactivated'} instead of {plan: 'deactivated', status: 'active'}
      if subscription.plan.id == config.SUBSCR.PLAN.DEACTIVATED
        obj.subscriptionStatus = config.SUBSCR.STATUS.DEACTIVATED
      else
        obj.subscriptionStatus = subscription.status
      return obj

  # last-ditch return NONE subscr/status, in an `else` so we dont prematurely return NONE during promises processing above
  else return obj


getSubscription = (userId) ->
  _getStripeIds(userId)
  .then ({stripe_customer_id, stripe_subscription_id, stripe_plan_id}) ->
    _getStripeSubscription stripe_customer_id, stripe_subscription_id, stripe_plan_id

  .catch isUnhandled, (err) ->
    throw new PartiallyHandledError(err, "We encountered an issue while accessing your subscription")


reactivate = (userId) -> Promise.try () ->
  dbs.transaction 'main', (transaction) ->
    _getStripeIds(userId, transaction)
    .then ({stripe_customer_id, stripe_subscription_id, stripe_plan_id}) ->
      if !stripe_plan_id?
        return {
          status: config.SUBSCR.PLAN.NONE
          created: null
        }

      promise = Promise.resolve()
      # if a stripe_subscription_id existings while reactivating, that means it should be a subscription plan that we need to cancel
      #   (for example "deactivated" subscription or a subscription in post-cancel grace period)
      if stripe_subscription_id?
        promise = promise.then () ->
          stripe.customers.cancelSubscription stripe_customer_id, stripe_subscription_id, {at_period_end: false}

      promise.then () ->
        payload =
          customer: stripe_customer_id
          plan: stripe_plan_id
          trial_end: 'now' # no trial period on reactivation

        stripe.subscriptions.create(payload)
        .then (created) ->
          tables.auth.user({transaction})
          .update stripe_subscription_id: created.id, stripe_plan_id: created.plan.id
          .where id: userId
          .then () ->
            status: created.status
            created: created

      .catch isUnhandled, (err) ->
        throw new PartiallyHandledError(err, "Encountered an issue reactivating the account, please contact customer service.")

# Called when user cancels subscription, going into grace period.
deactivate = (authUser, reason) ->
  dbs.transaction 'main', (transaction) ->
    stripe.customers.cancelSubscription authUser.stripe_customer_id, authUser.stripe_subscription_id, {at_period_end: true}
    .then (canceledSubscription) ->
      tables.history.user({transaction})
      .insert(auth_user_id: authUser.id, description: reason, category: 'account', subcategory: 'deactivation')
      .then () ->
        veroSvc.vero.createUserAndTrackEvent(
          veroSvc.user.getUniqueUserId(authUser)
          authUser.email
          authUser
          'subscription_canceled' # event name
          {} # event data
        )
        canceledSubscription

    .catch isUnhandled, (err) ->
      throw new PartiallyHandledError(err, "Encountered an issue deactivating the account, please contact customer service.")

module.exports = {
  updatePlan
  deactivatePlan
  getSubscription
  reactivate
  deactivate
  getStatus
}
