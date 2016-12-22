auth =  require '../utils/util.auth'
emailServices = require '../services/services.email'
logger = require('../config/logger').spawn('route:email')
{DataValidationError, validateAndTransformRequest} = require '../utils/util.validation'
emailTransforms = require('../utils/transforms/transforms.email')
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'


module.exports =
  # does not need login as this is meant for all emails not in the system yet
  # endpoint is for verifying an email address hash so that an email account is conidered non-spam
  verify:
    handleQuery: true
    handle: (req, res, next) ->
      validateAndTransformRequest req, emailTransforms.verifyRequest
      .then (validReq) ->
        emailServices.validateHash(validReq.params.hash)
      .then (bool) ->
        if bool
          "account validated via email"
      .catch DataValidationError, (err) ->
        next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
      .catch errorHandlingUtils.isUnhandled, (error) ->
        err = throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to validate email')
        next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})

  # Not locking this down as it is needed for OnBoarding (non-logged in users as well)
  isValid:
    method: 'post'
    handleQuery: true
    middleware: [
      auth.requireLogin(optional: true) #needed to put req.user into scope
    ]
    handle: (req, res, next) ->
      emailTransforms.validateRequest(req)
      .then (validReq) ->
        logger.debug -> "isValid: true"
        logger.debug -> validReq
        true
      .catch DataValidationError, (err) ->
        next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
      .catch errorHandlingUtils.isUnhandled, (error) ->
        err = throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to validate email')
        next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})
