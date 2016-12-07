# auth = require '../utils/util.auth'
emailServices = require '../services/services.email'
{mergeHandles} = require '../utils/util.route.helpers'
logger = require('../config/logger').spawn('route:email')
{wrapHandleRoutes} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
emailTransforms = require('../utils/transforms/transforms.email')
auth = require '../utils/util.auth'


handles = wrapHandleRoutes handles:
  verify: (req) ->
    validateAndTransformRequest req, emailTransforms.emailVerifyRequest
    .then (validReq) ->
      emailServices.validateHash(validReq.params.hash)
    .then (bool) ->
      if bool
        "account validated via email"

  isUnique: (req) ->
    logger.debug -> req.user

    transforms = emailTransforms.emailRequest(req.user?.id)

    validateAndTransformRequest(req, transforms)
    .then (validReq) ->
      logger.debug -> "isUnique: true"
      logger.debug -> validReq
      true


module.exports = mergeHandles handles,
  #does not need login as this is meant for all emails not in the system yet
  verify: {}
  #existing email check
  isUnique:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
