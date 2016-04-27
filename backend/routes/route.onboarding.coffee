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

submitPaymentPlan = ({plan, token, authUser, trx}) ->
  logger.debug "PaymentPlan: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  paymentServices.customers.create
    authUser: authUser
    plan: plan
    token: token
    trx: trx

submitEmail = ({authUser, plan, trx}) ->
  logger.debug "EmailService: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  emailServices.events.subscriptionSignUp
    authUser: authUser
    plan: plan
  .catch (error) ->
    logger.info "SignUp Failed, reverting Payment Customer"
    paymentServices.customers.handleCreationError
      error: error
      authUser:authUser
    throw error #rethrow error so transaction is reverted

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
              # (deprecated, we'll use subscription status and plan data off stripe isntead)
              tables.auth.m2m_user_group(transaction: trx)
              .insert user_id: parseInt(id), group_id: parseInt(groupId)
              .then ->
                id
          .then (id) ->
            logger.debug "new user (#{id}) inserted SUCCESS"
            tables.auth.user(transaction: trx).select(basicColumns.user.concat(["id"])...)
            .where id: parseInt id
          .then (authUser) ->
            expectSingleRow(authUser)
          .then (authUser) ->
            logger.debug {fips_code, mls_code, mls_id, plan}, true
            if !fips_code and !(mls_code and mls_id)
              throw new Error("fips_code or mls_code or mls_id is required for user location restrictions.")

            promise = null
            if fips_code
              promise = tables.auth.m2m_user_locations(transaction: trx)
              .insert(auth_user_id: authUser.id, fips_code: fips_code)

            if mls_id and mls_code and plan == 'pro'
              promise = tables.auth.m2m_user_mls(transaction: trx)
              .insert auth_user_id: authUser.id, mls_code: mls_code, mls_user_id: mls_id
            else
              promise = Promise.reject new Error 'invalid plan for mls setup'

            promise.then () -> authUser

            authUser
          .then (authUser) ->
            submitPaymentPlan {plan, token, authUser, trx}
          .then ({authUser, customer}) ->
            submitEmail {authUser, plan, customer}

module.exports = mergeHandles handles,
  createUser: method: "post"
