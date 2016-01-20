NamedError = require './util.error.named'

class InActiveUserError extends NamedError
  constructor: (args...) ->
    super('InActiveUser', args...)

class InValidEmailError extends NamedError
  constructor: (args...) ->
    super('InValidEmail', args...)

module.exports =
  InActiveUserError:InActiveUserError
  InValidEmailError: InValidEmailError
