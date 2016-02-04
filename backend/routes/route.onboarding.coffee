logger = require('../config/logger').spawn("route.onboarding")
{mergeHandles} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
{wrapHandleRoutes} = require '../utils/util.route.helpers'
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
    trx: trx
    authUser: authUser
    plan: plan
    token: token

submitEmail = ({authUser, plan, trx}) ->
  logger.debug "EmailService: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  emailServices.events.subscriptionSignUp
    authUser: authUser
    plan: plan
  .catch (error) ->
    logger.info "SignUp Failed, reverting Payment Customer"
    paymentServices.customers.handleCreationError
      error: error
      trx: trx
      authUser:authUser
    throw error #rethrow error so transaction is reverted

handles = wrapHandleRoutes
  createUser: (req) ->
    return throw new Error "OnBoarding API not ready" if !emailServices or !paymentServices
    # req = _.pick req, ['body', 'params', 'query']
    validateAndTransformRequest req, onboardingTransforms.createUser
    .then (validReq) ->
      {plan, token, fips_code, mls_code} = validReq.body
      plan = plan.name
      transaction 'main', (trx) ->
        entity = _.pick validReq.body, basicColumns.user
        entity.email_validation_hash = makeEmailHash()
        createPasswordHash entity.password
        .then (password) ->
          # console.log.magenta "password"
          entity.password = password

          tables.auth.user(trx).returning("id").insert entity
          .then (id) ->
            # console.log.magenta "inserted user"
            getPlanId(plan, trx)
            .then (groupId) ->
              # console.log.magenta "planId/groupId: #{groupId}"
              logger.debug "auth_user_id: #{id}"
              #give plan / group permissions
              tables.auth.m2m_user_group(trx)
              .insert user_id: parseInt(id), group_id: parseInt(groupId)
              .then ->
                id
          .then (id) ->
            logger.debug "new user (#{id}) inserted SUCCESS"
            tables.auth.user(trx).select(basicColumns.user.concat(["id"])...)
            .where id: parseInt id
          .then expectSingleRow
          .then (authUser) ->
            if !fips_code and !mls_code
              throw new Error("fips_code or mls_code required for user location restrictions.")
            promise = null
            if fips_code
              promise = tables.auth.m2m_user_locations(trx)
              .insert(auth_user_id: authUser.id, fips_code: fips_code)
            if mls_code
              promise = tables.auth.m2m_user_mls(trx)
              .insert(auth_user_id: authUser.id, mls_code: mls_code)

            promise.then () -> authUser

          .then (authUser) ->
            submitPaymentPlan {plan, token, authUser} #not including trx on purpose
          .then ({authUser, customer}) ->
            submitEmail {authUser, plan, customer}

module.exports = mergeHandles handles,
  createUser: method: "post"
