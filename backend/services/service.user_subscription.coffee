_ = require 'lodash'
config = require '../config/config'
Promise = require 'bluebird'
tables = require '../config/tables'
dbs = require '../config/dbs'
db = dbs.get('main')
logger = require('../config/logger').spawn("service.user_subscription")
permSvc = require './service.permissions'
{expectSingleRow} = require '../utils/util.sql.helpers'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'

stripe = null
require('../services/services.payment').then (svc) -> stripe = svc.stripe

_getStripeIds = (userId, trx) ->
  tables.auth.user(transaction: trx)
  .select 'stripe_customer_id', 'stripe_subscription_id'
  .where id: userId
  .then (result) ->
    expectSingleRow result
  .then (ids) ->
    ids

_getStripeSubscription = (stripe_customer_id, stripe_subscription_id) ->
  if !stripe_subscription_id?
    throw new Error("No subscription is associated with user #{stripe_customer_id}.")
  stripe.customers.retrieveSubscription stripe_customer_id, stripe_subscription_id
  .then (subscription) ->
    subscription

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

# deprecated code, using subscription status instead of user_group for
#   subscription-based access checks
setPlan = (userId, plan) ->
  getSubscription(userId)
  .then (res) ->

    # defensive checks
    if res.canceled_at
      throw new PartiallyHandledError(err, "Current subscription is cancelled, please re-enroll.")

    if res.plan?.id == config.SUBSCR.PLAN.PRO
      throw new PartiallyHandledError(err, "Current subscription is already premium status.")

    stripe.customers.cancelSubscription(res.customer, res.id)
    .then (cancelled) ->
      console.log "cancelled: \n#{JSON.stringify(cancelled)}"
      stripe.subscriptions.create({customer: res.customer, plan: config.SUBSCR.PLAN.PRO})
      .then (created) ->
        console.log "created:\n#{JSON.stringify(created)}"
        tables.auth.user()
        .update stripe_subscription_id: created.id
        .where id: userId
        .then () ->
          created

getStatus = (user) -> Promise.try () ->
  if !user.stripe_customer_id?  # if no subscription exists...
    if !user.is_staff  # ... and if not a staff, it's a subaccount
      return null
    permSvc.getPermissionsForUserId user.id
    .then (results) ->
      # return subscription level for the staff if granted a perm for it
      return config.SUBSCR.PLAN.PRO if results.access_premium
      return config.SUBSCR.PLAN.STANDARD if results.access_standard
      return null

  else # a stripe subscription exists, retrieve status
    _getStripeSubscription user.stripe_customer_id, user.stripe_subscription_id
    .then (subscription) ->
      if subscription.status == 'trialing' || subscription.status == 'active'
        # note: when a subscription is canceled or in grace period, this will still
        #   represent the plan id since this is access status, not just subscr status.
        #   Stripe will automatically change this subscr status at end of grace period.
        return subscription.plan.id
      # if not active, we'll just return the actual status in case we want to show or do
      #   specific things depending on past_due, canceled, etc.
      return subscription.status

getSubscription = (userId) ->
  _getStripeIds(userId)
  .then ({stripe_customer_id, stripe_subscription_id}) ->
    _getStripeSubscription stripe_customer_id, stripe_subscription_id
  .catch isUnhandled, (err) ->
    throw new PartiallyHandledError(err, "We encountered an issue while accessing your subscription")

deactivate = (userId) ->
  dbs.transaction 'main', (trx) ->
    _getStripeIds(userId, trx)
    .then ({stripe_customer_id, stripe_subscription_id}) ->
      stripe.customers.cancelSubscription stripe_customer_id, stripe_subscription_id, {at_period_end: true}
      .then (response) ->
        tables.user.project(transaction: trx)
        .update status: 'inactive'
        .where auth_user_id: userId
        .then () ->
          response
    .catch isUnhandled, (err) ->
      throw new PartiallyHandledError(err, "Encountered an issue deactivating the account, please contact customer service.")

module.exports =
  getPlan: getPlan
  setPlan: setPlan
  getSubscription: getSubscription
  deactivate: deactivate
  getStatus: getStatus
