NamedError = require './util.error.named'

class ValidateEmailError extends NamedError
  constructor: (args...) ->
    super('ValidateEmail', args...)

class ValidateEmailHashTimedOutError extends NamedError
  constructor: (args...) ->
    super('ValidateEmailHashTimedOut', args...)

module.exports =
  ValidateEmailError:ValidateEmailError
  ValidateEmailHashTimedOutError: ValidateEmailHashTimedOutError
