NamedError = require './util.error.named'

class StripeCardError extends NamedError
  constructor: (args...) ->
    super('StripeCard', args...)

class RateLimitError extends NamedError
  constructor: (args...) ->
    super('RateLimit', args...)

class StripeInvalidRequestError extends NamedError
  constructor: (args...) ->
    super('StripeInvalidRequest', args...)

class StripeAPIError extends NamedError
  constructor: (args...) ->
    super('StripeAPI', args...)

class StripeConnectionError extends NamedError
  constructor: (args...) ->
    super('StripeConnection', args...)

class StripeAuthenticationError extends NamedError
  constructor: (args...) ->
    super('StripeAuthentication', args...)

class CustomerCreateFailedError extends NamedError
  constructor: (args...) ->
    super('CustomerCreateFailed', args...)


module.exports =
  StripeCardError: StripeCardError
  RateLimitError: RateLimitError
  StripeInvalidRequestError: StripeInvalidRequestError
  StripeAPIError: StripeAPIError
  StripeConnectionError: StripeConnectionError
  StripeAuthenticationError: StripeAuthenticationError
  CustomerCreateFailedError: CustomerCreateFailedError
