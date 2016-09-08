NamedError = require './util.error.named'

class InActiveUserError extends NamedError
  constructor: (args...) ->
    super('InActiveUser', args...)

class InValidEmailError extends NamedError
  constructor: (args...) ->
    super('InValidEmail', args...)

class InValidPlanError extends NamedError
  constructor: (args...) ->
    super('InValidPlanError', args...)

class NeedsGroupPermissions extends NamedError
  constructor: (args...) ->
    super('NeedsGroupPermissions', args...)

module.exports = {
  InActiveUserError
  InValidEmailError
  InValidPlanError
  NeedsGroupPermissions
}
