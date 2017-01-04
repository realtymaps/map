auth =  require '../utils/util.auth'
emailServices = require '../services/services.email'
logger = require('../config/logger').spawn('route:email')
{DataValidationError, validateAndTransformRequest} = require '../utils/util.validation'
emailTransforms = require('../utils/transforms/transforms.email')
httpStatus = require '../../common/utils/httpStatus'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'

_isValid = (isLoggedIn) ->
  route =
    method: 'post'
    handleQuery: true
    handle: (req, res, next) ->
      emailTransforms.validateRequest(req)
      .then (validReq) ->
        logger.debug -> "isValid: true"
        logger.debug -> validReq
        true
      .catch DataValidationError, (err) ->
        throw new PartiallyHandledError(err, 'error interpreting query string parameters')
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to validate email')

  if isLoggedIn
    route.middleware =
      auth.requireLogin() #do not redirect or you will cause validations to pass!

  route


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
        throw new PartiallyHandledError(err, 'error interpreting query string parameters')
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to validate email')

  isValid: _isValid()
  isValidLoggedIn: _isValid(true)
