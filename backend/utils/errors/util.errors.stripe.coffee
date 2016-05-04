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

module.exports = _.extend {}, StripeErrors,
  CustomerCreateFailedError: CustomerCreateFailedError
  StripeEventHandlingError: StripeEventHandlingError
  handler: ourHandler
