_ = require 'lodash'
tables = require '../config/tables'
dbs = require '../config/dbs'
db = dbs.get('main')
logger = require('../config/logger').spawn("service.user_subscription")
{expectSingleRow} = require '../utils/util.sql.helpers'


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

deactivate = (userId) ->
  # acquire the deactivated plan group id
  # some of this logic would be replaced by calls to stripe plan
  tables.config.keystore()
  .select(
    db.raw("value->>\'group_id\' as deactivate_group_id")
  )
  .where key: 'deactivated', namespace: 'plans'
  .then (result) ->
    expectSingleRow result
  .then ({deactivate_group_id}) ->
    setPlan userId, deactivate_group_id
    .then (deactivatedPlan) ->
      tables.user.project()
      .update status: 'inactive'
      .where auth_user_id: userId
      .then () ->
        return deactivatedPlan

module.exports =
  getPlan: getPlan
  setPlan: setPlan
  deactivate: deactivate