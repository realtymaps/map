tables = require '../../config/tables'
{VALIDATION, EMAIL_VERIFY} = require '../../config/config'
{validators, validateAndTransformRequest} = require '../util.validation'
logger = require('../../config/logger').spawn("transforms:emails")
config = require '../../config/config'


# PRIVATE: do not make public use the the PUBLIC: valid  as id (uniqueness) is optional
# checks email regex only
_regex = ({regex} = {}) ->
  regex ?= [VALIDATION.email]

  if config.EMAIL_VERIFY.RESTRICT_TO_OUR_DOMAIN
    regex.push(VALIDATION.realtymapsEmail)

  validators.string({regex})

###
  Public: [Description]

 - `id` [Optional Int]  The auth_user_id to possibly allow its own email address.
 - `regex` [Optional String / Regex] - defaults to the email regex to test against
 - `doUnique` [Optional Bool] defaults to false
  Checks regex email always. If

###
valid = ({id, regex, doUnique = false} = {}) ->

  logger.debug -> {id, regex}

  transforms = [
    _regex({regex})
  ]

  if doUnique
    transforms.push validators.unique({
      tableFn: tables.auth.user
      id
      name: 'email'
      clauseGenFn: (value) ->
        email: value
    })

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


verifyRequest =
  params: validators.object subValidateSeparate:
    hash:
      transform: [validators.string(minLength: EMAIL_VERIFY.HASH_MIN_LENGTH)]
      required: true
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true


module.exports = {
  valid
  validateRequest
  verifyRequest
}
