_ = require 'lodash'
NamedError = require './util.error.named'
StripeErrors = require 'stripe/lib/Error'
handler = require '../util.handler'

CustomerCreateFailedError = StripeErrors.StripeError.extend(type: 'CustomerCreateFailedError')

ourHandler = (error, handles) ->
  handler {args: [error], handles}, () -> error.type

class StripeEventHandlingError extends NamedError
  constructor: (args...) ->
    super('StripeEventHandling', args...)

class GetAllStreamError extends NamedError
  constructor: (args...) ->
    super('GetAllStream', args...)

module.exports = _.extend {}, StripeErrors,
  CustomerCreateFailedError: CustomerCreateFailedError
  StripeEventHandlingError: StripeEventHandlingError
  handler: ourHandler
  GetAllStreamError: GetAllStreamError
