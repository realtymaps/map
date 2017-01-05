NamedError = require './util.error.named'
status = require '../../../common/utils/httpStatus'

class ValidateEmailError extends NamedError
  constructor: (args...) ->
    super('ValidateEmail', args...)

class ValidateEmailHashTimedOutError extends NamedError
  constructor: (args...) ->
    super('ValidateEmailHashTimedOut', args...)
    @returnStatus = status.BAD_REQUEST

module.exports =
  ValidateEmailError:ValidateEmailError
  ValidateEmailHashTimedOutError: ValidateEmailHashTimedOutError
