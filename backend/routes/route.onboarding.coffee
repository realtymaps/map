# _ = require 'lodash'
# tables = require '../config/tables'
logger = require '../config/logger'
{basicColumns} = require '../utils/util.sql.columns'
creditCardsService = require('../services/services.user').creditCards
creditCardCols = basicColumns.creditCards
# auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'
{validators} = require '../utils/util.validation'
logger = require '../config/logger'
{handleQuery, wrapHandleRoutes} = require '../utils/util.route.helpers'
{EMAIL_VERIFY, VALIDATION}= require '../config/config'
{validateAndTransform, falsyDefaultTransformsToNoop} = require '../utils/util.validation'

verifyTransforms =
  params: validators.object isEmptyProtect: true
  query:  validators.object isEmptyProtect: true
  body:
    password: validators.string(regex: VALIDATION.password)
    card:
      state: validators.object
        subValidateSeparate:
          account_image_id: validators.integer()

verifyTransforms = falsyDefaultTransformsToNoop(verifyTransforms)

handles = wrapHandleRoutes
  createUser: (req, res) ->
    validateAndTransform req, verifyTransforms
    .then (validReq) ->
      logger.debug.cyan validReq, true
      # handleQuery emailVerifyService(validReq.params.hash), res


module.exports = mergeHandles handles,
  createUser: {}
