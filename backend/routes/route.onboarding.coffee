# _ = require 'lodash'
# tables = require '../config/tables'
logger = require '../config/logger'
# auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
logger = require '../config/logger'
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

handles = wrapHandleRoutes
  createUser: (req) ->
    return throw new Error "OnBoarding API not ready" if !emailServices or !paymentServices
    # req = _.pick req, ['body', 'params', 'query']
    # logger.debug req, true
    validateAndTransformRequest req, onboardingTransforms.createUser
    .then (validReq) ->

      # console.log.cyan validReq.body, true
      transaction 'main', (trx) ->
        entity = _.pick validReq.body, basicColumns.user
        entity.email_validation_hash = makeEmailHash()
        createPasswordHash entity.password
        .then (password) ->
          entity.password = password

          logger.debug "will insert user entity of:"
          logger.debug entity, true
          logger.debug "inserting new user"
          tables.auth.user(trx).returning("id").insert entity
          .then (id) ->
            getPlanId(validReq.body.plan.name, trx)
            .then (groupId) ->
              logger.debug "planId/groupId: #{groupId}"
              logger.debug "auth_user_id: #{id}"
              #give plan / group permissions
              tables.auth.m2m_user_group(trx)
              .insert user_id: parseInt(id), group_id: parseInt(groupId)
              .then ->
                id
          .then (id) ->
            logger.debug "new user (#{id}) inserted SUCCESS"
            tables.auth.user(trx).select(basicColumns.user.concat(["id"])...).where id: parseInt id
          .then expectSingleRow
          .then (authUser) ->
            {fips_code, mls_code} = validReq.body
            if !fips_code and !mls_code
              throw new Error("fips_code or mls_code required for user location restrictions.")
            promise = null
            if fips_code
              promise = tables.auth.m2m_user_locations(trx)
              .insert(auth_user_id: authUser.id, fips_code: validReq.body.fips_code)
            if mls_code
              promise = tables.auth.m2m_user_mls(trx)
              .insert(auth_user_id: authUser.id, mls_code: validReq.body.mls_code)

            promise.then () -> authUser

          .then (authUser) ->
            logger.debug "PaymentPlan: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
            paymentServices.customers.create
              trx: trx
              authUser: authUser
              plan: validReq.body.plan.name
              token: validReq.body.token
          .then ({authUser, customer}) ->
            logger.debug "EmailService: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
            emailServices.events.subscriptionSignUp
              authUser: authUser
              plan: validReq.body.plan.name
            .catch (error) ->
              logger.info "SignUp Failed, reverting Payment Customer"
              paymentServices.customers.remove customer
              throw error #rethrow error so transaction is reverted


module.exports = mergeHandles handles,
  createUser: method: "post"
