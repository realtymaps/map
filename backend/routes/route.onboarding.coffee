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

handles = wrapHandleRoutes
  createUser: (req) ->
    validateAndTransformRequest req, onboardingTransforms.verify
    .then (validReq) ->
      logger.debug.cyan validReq, true
      transaction 'main', (trx) ->
        tables.auth.user(trx).returning("id").insert _.pick validReq.body, basicColumns.user
        .then (id) ->
          tables.auth.user(trx).select(basicColumns.user...).where id: id
        .then expectSingleRow
        .then (authUser) ->
          paymentServices.customers.create
            trx: trx
            authUser: authUser
            plan: validReq.body.plan.name
            safeCard: validReq.body.card
        .then ({authUser}) ->
          emailServices.events.signUp
            authUser: authUser

module.exports = mergeHandles handles,
  createUser: method: "post"
