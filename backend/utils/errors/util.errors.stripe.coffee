_ = require 'lodash'
NamedError = require './util.error.named'
StripeErrors = require 'stripe/lib/Error'
handler = require '../util.handler'
logger = require('../../config/logger').spawn('util:errors:stripe')

CustomerCreateFailedError = StripeErrors.StripeError.extend(type: 'CustomerCreateFailedError')

ourHandler = (error, handles) ->
  handler {args: [error], handles}, () -> error.type

class StripeEventHandlingError extends NamedError
  constructor: (args...) ->
    super('StripeEventHandling', args...)

class GetAllStreamError extends NamedError
  constructor: (args...) ->
    super('GetAllStream', args...)

class CustomerDoesNotExistError extends NamedError
  #to test a StripeError to us
  @is = (error, customer_id = '') ->
    l = logger.spawn('is')
    l.debug -> 'called'
    l.debug -> "error.message: #{error.message}"

    if error instanceof StripeErrors.StripeError || error instanceof CustomerDoesNotExistError
      l.debug -> 'passed instance'
      return ///.*No\ssuch\scustomer:\s#{customer_id}.*///.test(error.message)
    false

  constructor: (args...) ->
    super('CustomerDoesNotExist', args...)

module.exports = _.extend {}, StripeErrors, {
  handler: ourHandler
  CustomerCreateFailedError
  StripeEventHandlingError
  GetAllStreamError
  CustomerDoesNotExistError
}
