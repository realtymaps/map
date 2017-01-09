NamedError = require './util.error.named'
status = require '../../../common/utils/httpStatus'

class LoginError extends Error
  constructor: (args...) ->
    super(args...)
    Error.captureStackTrace(this, LoginError)
    @name = 'LoginError'
    @returnStatus = status.UNAUTHORIZED
    @expected = true
    @quiet = true

class InValidPlanError extends NamedError
  constructor: (args...) ->
    super('InValidPlanError', args...)

class NeedsGroupPermissions extends NamedError
  constructor: (args...) ->
    super('NeedsGroupPermissions', args...)

class NeedsLoginError extends Error
  constructor: (args...) ->
    super(args...)
    Error.captureStackTrace(this, NeedsLoginError)
    @name = 'NeedsLoginError'
    @returnStatus = status.UNAUTHORIZED
    @expected = true
    @quiet = true

class PermissionsError extends Error
  constructor: (args...) ->
    super(args...)
    Error.captureStackTrace(this, PermissionsError)
    @name = 'PermissionsError'
    @returnStatus = status.UNAUTHORIZED


module.exports = {
  LoginError
  InValidPlanError
  NeedsGroupPermissions
  NeedsLoginError
  PermissionsError
}
