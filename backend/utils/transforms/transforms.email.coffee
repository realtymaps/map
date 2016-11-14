tables = require '../../config/tables'
{VALIDATION, EMAIL_VERIFY} = require '../../config/config'
{validators} = require '../util.validation'
clsFactory = require '../util.cls'
logger = require('../../config/logger').spawn("transforms:emails")
config = require '../../config/config'

email = (id, {tableFn, regex}) ->
  tableFn ?= tables.auth.user
  regex ?= [VALIDATION.email]

  if config.EMAIL_VERIFY.RESTRICT_TO_OUR_DOMAIN
    regex.push(VALIDATION.real)

  id ?= clsFactory().getCurrentUserId()

  transform: [
    validators.string({regex})
    validators.unique {
      tableFn
      id
      name: 'email'
      clauseGenFn: (value) ->
        email: value
    }
  ]
  required: true

emailRequest = (id) ->
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    email: email(id)

emailVerifyRequest =
  params: validators.object subValidateSeparate:
    hash:
      transform: [validators.string(minLength: EMAIL_VERIFY.HASH_MIN_LENGTH)]
      required: true
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true


module.exports = {
  email
  emailRequest
  emailVerifyRequest
}
