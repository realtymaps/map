# auth = require '../utils/util.auth'
emailServices = require '../services/services.email'
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
      emailServices.validateHash(validReq.params.hash)

  isUnique: (req) ->
    logger.debug "isUnique"
    transforms = emailTransforms.emailRequest(req.user?.id)
    logger.debug transforms, true
    validateAndTransformRequest(req, transforms)
    .then (validReq) ->
      logger.debug "isUnique: true"
      logger.debug validReq, true
      true


module.exports = mergeHandles handles,
  verify: {}
  isUnique:
    method: 'post'
