tables = require '../../config/tables'
{VALIDATION, EMAIL_VERIFY} = require '../../config/config'
{validators} = require '../util.validation'
clsFactory = require '../util.cls'
logger = require('../../config/logger').spawn("transforms:emails")
config = require '../../config/config'

validEmail = ({regex} = {}) ->
  regex ?= [VALIDATION.email]
  if config.EMAIL_VERIFY.RESTRICT_TO_OUR_DOMAIN
    regex.push(VALIDATION.realtymapsEmail)
  validators.string({regex})

uniqueEmail = (id, {tableFn, regex} = {}) ->
  tableFn ?= tables.auth.user

  logger.debug -> "pre cls id: #{id}"

  id ?= clsFactory().getCurrentUserId()

  logger.debug -> {id, regex}

  transform: [
    validEmail({regex})
    validators.unique({
      tableFn
      id
      name: 'email'
      clauseGenFn: (value) ->
        email: value
    })
  ]
  required: true

emailRequest = (id) ->
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    email: uniqueEmail(id)

emailVerifyRequest =
  params: validators.object subValidateSeparate:
    hash:
      transform: [validators.string(minLength: EMAIL_VERIFY.HASH_MIN_LENGTH)]
      required: true
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true


module.exports = {
  validEmail
  uniqueEmail
  emailRequest
  emailVerifyRequest
}
