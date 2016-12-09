# auth = require '../utils/util.auth'
emailServices = require '../services/services.email'
{mergeHandles} = require '../utils/util.route.helpers'
logger = require('../config/logger').spawn('route:email')
{validateAndTransformRequest} = require '../utils/util.validation'
emailTransforms = require('../utils/transforms/transforms.email')
auth = require '../utils/util.auth'

module.exports =
  #does not need login as this is meant for all emails not in the system yet
  verify:
    handleQuery: true
    handle: (req) ->
      validateAndTransformRequest req, emailTransforms.emailVerifyRequest
      .then (validReq) ->
        emailServices.validateHash(validReq.params.hash)
      .then (bool) ->
        if bool
          "account validated via email"

  #existing email check
  isUnique:
    method: 'post'
    handleQuery: true
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req) ->
      logger.debug -> req.user

      transforms = emailTransforms.emailRequest(req.user?.id)

      validateAndTransformRequest(req, transforms)
      .then (validReq) ->
        logger.debug -> "isUnique: true"
        logger.debug -> validReq
        true
