# auth = require '../utils/util.auth'
emailVerifyService = require '../services/service.emailVerify'
{mergeHandles} = require '../utils/util.route.helpers'
logger = require '../config/logger'
{wrapHandleRoutes} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
emailTransforms = require('../utils/transforms/transforms.email')


handles = wrapHandleRoutes
  verify: (req) ->
    validateAndTransformRequest req, emailTransforms.emailVerifyRequest
    .then (validReq) ->
      logger.debug.cyan validReq, true
      emailVerifyService(validReq.params.hash)

  isUnique: (req) ->
    logger.debug "isUnique"
    transforms = emailTransforms.emailRequest(req.user?.id)
    logger.debug.yellow transforms, true
    validateAndTransformRequest(req, transforms)
    .then (validReq) ->
      logger.debug "isUnique: true"
      logger.debug validReq, true
      true


module.exports = mergeHandles handles,
  verify: {}
  isUnique:
    method: 'post'
