NamedError = require './util.error.named'
status = require '../../../common/utils/httpStatus'

class EmailError extends NamedError
  constructor: (args...) ->
    super('EmailError', args...)
    @returnStatus = status.BAD_REQUEST

class ValidateEmailError extends EmailError
  constructor: (args...) ->
    super('ValidateEmailError', args...)
    @quiet = true
    @expected = true

class VerifyEmailError extends EmailError
  constructor: (args...) ->
    super('VerifyEmailError', args...)

class ValidateEmailHashTimedOutError extends EmailError
  constructor: (args...) ->
    super('ValidateEmailHashTimedOutError', args...)


module.exports = {
  EmailError
  ValidateEmailError
  ValidateEmailHashTimedOutError
}
