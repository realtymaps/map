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
{SignUpError} = require '../utils/errors/util.errors.vero'
encryptor =  require '../config/encryptor'

handles = wrapHandleRoutes
  createUser: (req) ->
    return throw new Error "OnBoarding API not ready" if !emailServices or !paymentServices
    # req = _.pick req, ['body', 'params', 'query']
    # logger.debug req, true
    validateAndTransformRequest req, onboardingTransforms.createUser
    .then (validReq) ->

      # logger.debug.cyan validReq, true
      transaction 'main', (trx) ->
        entity = _.pick validReq.body, basicColumns.user
        entity.email_validation_hash = makeEmailHash()
        entity.password = encryptor.encrypt entity.password

        logger.debug "will insert user entity of:"
        logger.debug entity, true
        logger.debug "inserting new user"
        tables.auth.user(trx).returning("id").insert entity
        .then (id) ->
          logger.debug "new user (#{id}) inserted SUCCESS"
          tables.auth.user(trx).select(basicColumns.user.concat(["id"])...).where id: parseInt id
        .then expectSingleRow
        .then (authUser) ->
          logger.debug "PaymentPlan: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
          paymentServices.customers.create
            trx: trx
            authUser: authUser
            plan: validReq.body.plan.name
            token: validReq.body.token
        .then ({authUser, customer}) ->
          logger.debug "EmailService: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
          emailServices.events.signUp
            authUser: authUser
            plan: validReq.body.plan.name
          .catch (error) ->
            logger.info "SignUp Failed, reverting Payment Customer"
            paymentServices.customers.remove customer
            throw error #rethrow error so transaction is reverted


module.exports = mergeHandles handles,
  createUser: method: "post"
