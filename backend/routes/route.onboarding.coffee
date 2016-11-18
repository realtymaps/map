{PAYMENT_PLATFORM} = require '../config/config'
logger = require('../config/logger').spawn("route.onboarding")
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')
emailServices = null
paymentServices = null
{makeEmailHash, emailPlatform} = require('../services/services.email')
emailPlatform.then (svc) ->
  emailServices = svc
require('../services/services.payment').then (svc) ->
  paymentServices = svc
{basicColumns} = require '../utils/util.sql.columns'
tables = require '../config/tables'
_ = require 'lodash'
{expectSingleRow} = require '../utils/util.sql.helpers'
{transaction} = require '../config/dbs'
{createPasswordHash} =  require '../services/service.userSession'
{getPlanId} = require '../services/service.plans'
mlsAgentService = require '../services/service.mls.agent'
errors = require '../utils/errors/util.errors.onboarding'
internals = require './route.onboarding.internals'


handles = wrapHandleRoutes handles:
  createUser: (req) ->
    return throw new Error "OnBoarding API not ready" if !emailServices or !paymentServices
    # req = _.pick req, ['body', 'params', 'query']
    validateAndTransformRequest req, onboardingTransforms.createUser
    .then (validReq) ->
      {plan, token, fips_code, mls_code, mls_id} = validReq.body
      plan = plan.name
      transaction 'main', (trx) ->
        entity = _.pick validReq.body, basicColumns.user
        entity.email_validation_hash = makeEmailHash()
        entity.is_test = !PAYMENT_PLATFORM.LIVE_MODE
        entity.is_active = true # if we demand email validation again, then remove this line
        createPasswordHash entity.password
        .then (password) ->
          # console.log.magenta "password"
          entity.password = password

          tables.auth.user(transaction: trx).returning("id").insert entity
          .then (id) ->
            # console.log.magenta "inserted user"
            getPlanId(plan, trx)
            .then (groupId) ->
              # console.log.magenta "planId/groupId: #{groupId}"
              logger.debug "auth_user_id: #{id}"
              #give plan / group permissions
              # (deprecated, we'll use subscription status and plan data off stripe instead)
              tables.auth.m2m_user_group(transaction: trx)
              .insert user_id: parseInt(id), group_id: parseInt(groupId)
              .then ->
                id
          .then (id) ->
            logger.debug "new user (#{id}) inserted SUCCESS"
            tables.auth.user(transaction: trx).select(basicColumns.user.concat("id")...)
            .where id: parseInt id
          .then (authUser) ->
            expectSingleRow(authUser)
          .then (authUser) ->
            logger.debug {fips_code, mls_code, mls_id, plan}, true
            if !fips_code && !(mls_code && mls_id)
              throw new Error("fips_code or mls_code or mls_id is required for user location restrictions.")

            promises = []
            if fips_code
              promises.push(tables.auth.m2m_user_locations(transaction: trx)
              .insert(auth_user_id: authUser.id, fips_code: fips_code))

            if mls_id? && mls_code? && plan == 'pro'
              promises.push(
                mlsAgentService.exists(data_source_id: mls_code, license_number: mls_id)
                .then (is_verified) ->
                  if !is_verified
                    throw new errors.MlsAgentNotVierified("Agent not verified for mls_id: #{mls_id}, mls_code: #{mls_code} for email: #{authUser.email}")
                  tables.auth.m2m_user_mls(transaction: trx)
                  .insert({auth_user_id: authUser.id, mls_code: mls_code, mls_user_id: mls_id, is_verified})
              )

            Promise.all promises
            .then () ->
              internals.setNewUserMapPosition({authUser, transaction: trx})
            .then () -> authUser

          .then (authUser) ->
            internals.submitPaymentPlan {plan, token, authUser, trx}
          .then ({authUser, customer}) ->
            internals.submitEmail {authUser, plan, customer}

module.exports = mergeHandles handles,
  createUser: method: "post"
