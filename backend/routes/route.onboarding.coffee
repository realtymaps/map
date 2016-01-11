# _ = require 'lodash'
# tables = require '../config/tables'
logger = require '../config/logger'
{basicColumns} = require '../utils/util.sql.columns'
creditCardsService = require('../services/services.user').creditCards
creditCardCols = basicColumns.creditCards
# auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
logger = require '../config/logger'
{wrapHandleRoutes} = require '../utils/util.route.helpers'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')

handles = wrapHandleRoutes
  createUser: (req) ->
    validateAndTransformRequest req, onboardingTransforms.verify
    .then (validReq) ->
      logger.debug.cyan validReq, true
      # handleQuery emailVerifyService(validReq.params.hash), res


module.exports = mergeHandles handles,
  createUser: {}
