_ = require 'lodash'
tables = require '../config/tables'
dbs = require '../config/dbs'
db = dbs.get('main')
logger = require('../config/logger').spawn("service.user_subscription")
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

getPlan = (userId) ->
  tables.auth.m2m_user_group()
  .select(
    "#{tables.auth.m2m_user_group.tableName}.group_id as group_id",
    "#{tables.auth.group.tableName}.name as group_name"
  )
  .where "#{tables.auth.m2m_user_group.tableName}.user_id": userId
  .join("#{tables.auth.group.tableName}", () ->
    this.on("#{tables.auth.group.tableName}.id", "#{tables.auth.m2m_user_group.tableName}.group_id")
  )
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

setPlan = (userId, plan) ->
  tables.auth.m2m_user_group()
  .update group_id: plan
  .where user_id: userId
  .then (result) ->
    getPlan userId
    .then (newPlan) ->
      newPlan

getSubscription = (userId) ->
  _getStripeIds(userId)
  .then ({stripe_customer_id, stripe_subscription_id}) ->
    if !stripe_subscription_id?
      throw new Error("No subscription is associated with user #{stripe_customer_id}.")
    stripe.customers.retrieveSubscription stripe_customer_id, stripe_subscription_id
    .then (subscription) ->
      subscription

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