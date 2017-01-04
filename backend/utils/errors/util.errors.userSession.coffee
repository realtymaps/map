NamedError = require './util.error.named'
status = require '../../../common/utils/httpStatus'

class InActiveUserError extends NamedError
  constructor: (args...) ->
    super('InActiveUser', args...)
    @returnStatus = status.UNAUTHORIZED

class InValidPlanError extends NamedError
  constructor: (args...) ->
    super('InValidPlanError', args...)

class NeedsGroupPermissions extends NamedError
  constructor: (args...) ->
    super('NeedsGroupPermissions', args...)

module.exports = {
  InActiveUserError
  InValidPlanError
  NeedsGroupPermissions
}
