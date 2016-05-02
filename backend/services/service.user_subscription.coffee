_ = require 'lodash'
tables = require '../config/tables'
dbs = require '../config/dbs'
db = dbs.get('main')
logger = require('../config/logger').spawn("service.user_subscription")
{expectSingleRow} = require '../utils/util.sql.helpers'

stripe = null
require('../services/services.payment').then (svc) -> stripe = svc.stripe

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

setPlan = (userId, plan) ->
  tables.auth.m2m_user_group()
  .update group_id: plan
  .where user_id: userId
  .then (result) ->
    getPlan userId
    .then (newPlan) ->
      newPlan

getStatus = (subscriptionId) ->
  "premium"

deactivate = (userId) ->
  # acquire the deactivated plan group id
  # some of this logic would be replaced by better subscription handling we impl in future
  tables.auth.user()
  .select 'stripe_customer_id'
  .where id: userId
  .then (result) ->
    expectSingleRow result
  .then ({stripe_customer_id}) ->
    stripe.customers.listSubscriptions stripe_customer_id
    .then (subscription) ->
      sub_id = subscription.data[0].id
      stripe.customers.cancelSubscription stripe_customer_id, sub_id, {at_period_end: true}
      .then (response) ->
        tables.user.project()
        .update status: 'inactive'
        .where auth_user_id: userId
        .then () ->
          plan: _.merge response.plan,
            current_period_end: response.current_period_end
            canceled_at: response.canceled_at
    .catch (err) ->
      throw new Error(err, "Encountered an issue deactivating the account, please contact customer service.")

module.exports =
  getPlan: getPlan
  setPlan: setPlan
  deactivate: deactivate
  getStatus: getStatus
