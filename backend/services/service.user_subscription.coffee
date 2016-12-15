_ = require 'lodash'
config = require '../config/config'
Promise = require 'bluebird'
tables = require '../config/tables'
dbs = require '../config/dbs'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("service.user_subscription")
# coffeelint: enable=check_scope
permSvc = require './service.permissions'
{expectSingleRow} = require '../utils/util.sql.helpers'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
stripeErrors = require '../utils/errors/util.errors.stripe'

stripe = null
require('../services/services.payment').then (svc) -> stripe = svc.stripe


# Return "dummy" subscription objects that emulates a stripe subscription
# For use when canceled subscription data is no longer available from stripe
expiredSubscription = (planId) ->
  status: config.SUBSCR.PLAN.EXPIRED
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


_getStripeIds = (userId, trx) ->
  tables.auth.user(transaction: trx)
  .select 'stripe_customer_id', 'stripe_subscription_id', 'stripe_plan_id'
  .where id: userId
  .then (result) ->
    expectSingleRow result
  .then (ids) ->
    ids


# deprecated code, using subscription status instead of user_group for
#   subscription-based access checks
getPlan = (userId) ->
  tables.auth.m2m_user_group()
  .select(
    "#{tables.auth.m2m_user_group.tableName}.group_id as group_id",
    "#{tables.auth.group.tableName}.name as group_name"
  )
  .where "#{tables.auth.m2m_user_group.tableName}.user_id": userId
  .join "#{tables.auth.group.tableName}", () ->
    this.on("#{tables.auth.group.tableName}.id", "#{tables.auth.m2m_user_group.tableName}.group_id")
  .then (plan) ->
    expectSingleRow plan
  .then (plan) ->
    planName = plan.group_name
    planKey = planName.substring(0, planName.indexOf(' ')).toLowerCase()
    # this should eventually be replaced with stripe plan or metadata in the future
    tables.config.keystore()
    .select 'value'
    .where key: planKey
    .then (result) ->
      expectSingleRow result
    .then (planDetails) ->
      _.merge plan, planDetails.value


# requires a STRIPE subscription object with a status and plan keys in order to determine status string
_getStatusString = (subscription) ->
  if subscription.status == 'trialing' || subscription.status == 'active'

    # note: when a subscription is canceled or in grace period, this will still
    #   represent the plan id since this is access status, not just subscr status.
    #   Stripe will automatically change this subscr status at end of grace period.
    # Note: includes plan.id `deactivated`
    return subscription.plan.id

  # if not active, we'll just return the actual status in case we want to show or do
  #   specific things depending on past_due, canceled, etc.
  # NOTE: a status of 'expired' is set by us since stripe deletes inactive subscriptions
  return subscription.status


# update plan among paid subscription levels
updatePlan = (userId, plan) ->
  if !(plan in config.SUBSCR.PLAN.PAID_LIST)
    throw new PartiallyHandledError("Cannot upgrade to plan #{plan} because it is invalid.")

  getSubscription(userId)
  .then (res) ->

    # defensive checks, just return the subscription if it's the same plan as needing set
    if res.plan?.id == plan
      return {
        status: _getStatusString(res)
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
        status: _getStatusString(updated)
        updated: updated


# returns a status for `session.subscription` to use for subscription level access
getStatus = (user) -> Promise.try () ->

  # stripe_customer or stripe_subscr may not exist for staff, client subusers, etc...
  if !user.stripe_customer_id? || !user.stripe_subscription_id? # if no customer or subscription exists...

    # check internal permissions (special case stuff like for superuser or staff is handled there)...
    permSvc.getPermissionsForUserId user.id
    .then (results) ->
      # return subscription level for the staff if granted a perm for it
      return config.SUBSCR.PLAN.PRO if results.access_premium
      return config.SUBSCR.PLAN.STANDARD if results.access_standard

      return config.SUBSCR.PLAN.NONE

  # a customer with a stripe_plan_id implies we either have or had a subscription, so try to get it...
  else if user.stripe_plan_id? # a stripe subscription exists, retrieve status
    _getStripeSubscription user.stripe_customer_id, user.stripe_subscription_id, user.stripe_plan_id
    .then (subscription) ->
      return _getStatusString(subscription)

  else return config.SUBSCR.PLAN.NONE


getSubscription = (userId) ->
  _getStripeIds(userId)
  .then ({stripe_customer_id, stripe_subscription_id, stripe_plan_id}) ->
    _getStripeSubscription stripe_customer_id, stripe_subscription_id, stripe_plan_id

  .catch isUnhandled, (err) ->
    throw new PartiallyHandledError(err, "We encountered an issue while accessing your subscription")


reactivate = (userId) -> Promise.try () ->
  console.log "\n\n##########\nreactivate()"
  dbs.transaction 'main', (trx) ->
    _getStripeIds(userId, trx)
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
          console.log "\n\ncanceling subscription..."
          stripe.customers.cancelSubscription stripe_customer_id, stripe_subscription_id, {at_period_end: false}
          .then (res) ->
            console.log "canceled, res:\n#{JSON.stringify(res,null,2)}"

      promise.then () ->
        payload =
          customer: stripe_customer_id
          plan: stripe_plan_id
          trial_end: 'now' # no trial period on reactivation

        console.log "\n\ncreating subscription\npayload:\n#{JSON.stringify(payload,null,2)}"
        stripe.subscriptions.create(payload)
        .then (created) ->
          console.log "created, created:\n#{JSON.stringify(created,null,2)}"
          tables.auth.user(transaction: trx)
          .update stripe_subscription_id: created.id, stripe_plan_id: created.plan.id
          .where id: userId
          .then () ->
            console.log "completed local id update"
            status: _getStatusString(created)
            created: created
          .catch (err) ->
            analyzeValue = require '../../common/utils/util.analyzeValue'
            console.log "err:\n#{analyzeValue.getSimpleMessage(error)}"

      .catch isUnhandled, (err) ->
        throw new PartiallyHandledError(err, "Encountered an issue reactivating the account, please contact customer service.")


deactivate = (userId, reason) ->
  dbs.transaction 'main', (trx) ->
    _getStripeIds(userId, trx)
    .then ({stripe_customer_id, stripe_subscription_id}) ->
      stripe.customers.cancelSubscription stripe_customer_id, stripe_subscription_id, {at_period_end: true}
      .then (canceledSubscription) ->
        tables.user.history(transaction: trx)
        .insert(auth_user_id: userId, description: reason, category: 'account', subcategory: 'deactivation')
        .then () ->
          canceledSubscription

    .catch isUnhandled, (err) ->
      throw new PartiallyHandledError(err, "Encountered an issue deactivating the account, please contact customer service.")

module.exports = {
  getPlan
  updatePlan
  getSubscription
  reactivate
  deactivate
  getStatus
}
