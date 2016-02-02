_ = require 'lodash'
StripeErrors = require 'stripe/lib/error'
handler = require '../util.handler'

CustomerCreateFailedError = StripeErrors.StripeError.extend(type: 'CustomerCreateFailedError')

ourHandler = (error, handles) ->
  handler {args: [error], handles}, () -> error.type

module.exports = _.extend StripeErrors,
  CustomerCreateFailedError: CustomerCreateFailedError
  handler: ourHandler
