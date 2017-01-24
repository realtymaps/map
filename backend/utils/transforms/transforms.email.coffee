tables = require '../../config/tables'
{VALIDATION, EMAIL_VERIFY} = require '../../config/config'
{validators, validateAndTransformRequest, DataValidationError} = require '../util.validation'
logger = require('../../config/logger').spawn("transforms:emails")
config = require '../../config/config'
errorHandlingUtils = require '../errors/util.error.partiallyHandledError'
emailErrors = require '../errors/util.errors.email'


# PRIVATE: do not make public use the the PUBLIC: valid  as id (uniqueness) is optional
# checks email regex only
email = (regexes) ->
  regexes ?= [VALIDATION.email]

  if config.EMAIL_VERIFY.RESTRICT_TO_OUR_DOMAIN
    regexes.push(VALIDATION.realtymapsEmail)

  validators.string({regex:regexes})

###
  Public: [Description]

 - `id` [Optional Int]  The auth_user_id to possibly allow its own email address.
 - `regex` [Optional String / Regex] - defaults to the email regex to test against
 - `doUnique` [Optional Bool] defaults to false
  Checks regex email always. If

###
valid = ({id, doUnique = false} = {}) ->

  logger.debug -> {id, doUnique}

  transforms = [email()]

  if doUnique
    transforms.push validators.unique({
      tableFn: tables.auth.user
      id
      name: 'email'
      clauseGenFn: (value) ->
        email: value
    })

  logger.debug -> "transforms"
  logger.debug -> transforms

  transforms

validateRequest = (req) ->
  #first validation is to get possible doUnique and if email even exists
  validateAndTransformRequest(req, {
    params: validators.object isEmptyProtect: true
    query: validators.object isEmptyProtect: true
    body: validators.object subValidateSeparate:
      email:
        transform: validators.string(minLength: 2)
        required: true
      doUnique: validators.boolean(truthy: true, falsy: false)
  })
  .then (validReq) ->
    {doUnique} = validReq.body
    id = req.user?.id
    logger.debug -> "req.user.id: #{id}"
    logger.debug -> "doUnique: #{doUnique}"

    #second validation actually run the email validation along with option uniqueness check
    validateAndTransformRequest(validReq, {
      body: validators.object subValidateSeparate:
        email:
          transform: valid({id, doUnique})
          required: true
    })
    .catch DataValidationError, (err) ->
      throw new emailErrors.ValidateEmailError(err, 'problem validating email string')
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to validate email')


verifyRequest =
  params: validators.object subValidateSeparate:
    hash:
      transform: [validators.string(minLength: EMAIL_VERIFY.HASH_MIN_LENGTH)]
      required: true
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true


module.exports = {
  email
  valid
  validateRequest
  verifyRequest
}
