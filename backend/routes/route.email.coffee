# auth = require '../utils/util.auth'
emailVerifyService = require '../services/service.emailVerify'
{mergeHandles} = require '../utils/util.route.helpers'
logger = require '../config/logger'
{handleQuery, wrapHandleRoutes} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
emailTransforms = require('../utils/transforms/transforms.email')


handles = wrapHandleRoutes
  verify: (req, res) ->
    validateAndTransformRequest req, emailTransforms.emailVerifyRequest
    .then (validReq) ->
      logger.debug.cyan validReq, true
      handleQuery emailVerifyService(validReq.params.hash), res

  isUnique: (req, res) ->
    transforms =
      email: emailTransforms.emailRequest(req.user?.id)

    validateAndTransformRequest(req, transforms)
    .then () ->
      true


module.exports = mergeHandles handles,
  verify: {}
  isUnique:
    method: 'post'
