# auth = require '../utils/util.auth'
emailVerifyService = require '../services/service.emailVerify'
{mergeHandles} = require '../utils/util.route.helpers'
{validators} = require '../utils/util.validation'
logger = require '../config/logger'
{handleQuery, wrapHandleRoutes} = require '../utils/util.route.helpers'
{EMAIL_VERIFY}= require '../config/config'
{validateAndTransform, falsyDefaultTransformsToNoop} = require '../utils/util.validation'

verifyTransforms =
  params:
    hash:
      required: true
      transform: [validators.string(minLength: EMAIL_VERIFY.HASH_MIN_LENGTH, maxLength:EMAIL_VERIFY.HASH_MIN_LENGTH)]
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true

verifyTransforms = falsyDefaultTransformsToNoop(verifyTransforms)

handles = wrapHandleRoutes
  verify: (req, res) ->
    validateAndTransform req, verifyTransforms
    .then (validReq) ->
      logger.debug.cyan validReq, true
      handleQuery emailVerifyService(validReq.params.hash), res


module.exports = mergeHandles handles,
  verify: {}
