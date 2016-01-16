tables = require '../../config/tables'
{VALIDATION, EMAIL_VERIFY} = require '../../config/config'
{validators} = require '../util.validation'

email = (optUserId) ->
  transform: [
      validators.string(regex: VALIDATION.email)
      validators.unique tableFn: tables.auth.user, id: optUserId, name: 'email', clauseGenFn: (value) ->
        email: value
  ]
  required: true

emailRequest = (optUserId) ->
  params: validators.object isEmptyProtect: true
  query:  validators.object isEmptyProtect: true
  body:   validators.object subValidateSeparate:
    email: email(optUserId)

emailVerifyRequest =
  params: validators.object subValidateSeparate:
    hash:
      transform: [validators.string(minLength: EMAIL_VERIFY.HASH_MIN_LENGTH)]
      required: true
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true


module.exports =
  email: email
  emailRequest: emailRequest
  emailVerifyRequest: emailVerifyRequest
