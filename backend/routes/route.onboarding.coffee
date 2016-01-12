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
userService = require('../services/services.user').user
{basicColumns} = require '../utils/util.sql.columns'


handles = wrapHandleRoutes
  createUser: (req) ->
    validateAndTransformRequest req, onboardingTransforms.verify
    .then (validReq) ->
      logger.debug.cyan validReq, true
      #TODO make this one atomic transaction might need to use dbs.getKnex
      #begin transaction
      userService.create validReq.body, undefined, true, basicColumns.user
      .then (id) ->
        userService.getById(id)
      .then (authUser) ->
        paymentServices.customers.create
          authUser: authUser
          plan: validReq.body.plan.name
          safeCard: validReq.body.card
      .then ({authUser}) ->
        emailServices.events.signUp
          authUser: authUser
      #end transaction



module.exports = mergeHandles handles,
  createUser: {}
