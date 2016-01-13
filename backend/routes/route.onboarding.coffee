# _ = require 'lodash'
# tables = require '../config/tables'
logger = require '../config/logger'
# auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
logger = require '../config/logger'
{wrapHandleRoutes} = require '../utils/util.route.helpers'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')
emailServices = require '../services/services.email'
paymentServices = require '../services/services.payment'
{basicColumns} = require '../utils/util.sql.columns'
tables = require '../config/tables'
_ = require 'lodash'
{expectSingleRow} = require '../utils/util.sql.helpers'
{transaction} = require '../config/dbs'
{SignUpError} = require '../utils/errors/util.errors.vero'

handles = wrapHandleRoutes
  createUser: (req) ->
    req = _.pick req, ['body', 'params', 'query']
    logger.debug req, true
    validateAndTransformRequest req, onboardingTransforms.createUser
    .then (validReq) ->
      logger.debug.cyan validReq, true
      transaction 'main', (trx) ->
        entity = _.pick validReq.body, basicColumns.user
        logger.debug "will insert user entity of:"
        logger.debug entity, true
        q = tables.auth.user(trx).returning("id").insert entity
        logger.debug "inserting new user"
        logger.debug q.toString()
        q.then (id) ->
          logger.debug "new user inserted SUCCESS"
          tables.auth.user(trx).select(basicColumns.user...).where id: id
        .then expectSingleRow
        .then (authUser) ->
          paymentServices.customers.create
            trx: trx
            authUser: authUser
            plan: validReq.body.plan.name
            safeCard: validReq.body.card
        .then (payload) ->
          emailServices.events.signUp
            authUser: payload.authUser
          .catch SignUpError, (error) ->
            logger.info "SignUp Failed, reverting Payment Customer"
            paymentServices.customers.remove payload
            throw error #rethrow error so transaction is reverted


module.exports = mergeHandles handles,
  createUser: method: "post"
