NamedError = require './util.error.named'
httpStatus = require '../../../common/utils/httpStatus'

class MlsAgentNotVerified extends NamedError
  constructor: (args...) ->
    super('MlsAgentNotVerified', args...)
    @returnStatus = httpStatus.UNAUTHORIZED

class UserExists extends NamedError
  constructor: (args...) ->
    super('UserExists', args...)
    @returnStatus = httpStatus.UNAUTHORIZED

class UserExists extends NamedError
  constructor: (args...) ->
    super('UserExists', args...)
    @returnStatus = httpStatus.UNAUTHORIZED

class SubmitPaymentPlanError extends NamedError
  constructor: (args...) ->
    super('SubmitPaymentPlanError', args...)
    @returnStatus = httpStatus.UNAUTHORIZED

class SubmitPaymentPlanCreateCustomerError extends NamedError
  constructor: (args...) ->
    super('SubmitPaymentPlanCreateCustomerError', args...)
    @returnStatus = httpStatus.UNAUTHORIZED

module.exports = {
  MlsAgentNotVerified
  UserExists
  SubmitPaymentPlanError
  SubmitPaymentPlanCreateCustomerError
}
