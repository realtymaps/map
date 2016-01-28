NamedError = require './util.error.named'

class LobRateLimitError extends NamedError
  constructor: (args...) ->
    super('LobRateLimit', args...)

class LobNotFoundError extends NamedError
  constructor: (args...) ->
    super('LobNotFound', args...)

class LobBadRequestError extends NamedError
  constructor: (args...) ->
    super('LobBadRequest', args...)

class LobServerError extends NamedError
  constructor: (args...) ->
    super('LobServer', args...)

class LobForbiddenError extends NamedError
  constructor: (args...) ->
    super('LobForbidden', args...)

class LobUnauthorizedError extends NamedError
  constructor: (args...) ->
    super('LobUnauthorized', args...)


module.exports =
  LobRateLimitError: LobRateLimitError
  LobNotFoundError: LobNotFoundError
  LobBadRequestError: LobBadRequestError
  LobServerError: LobServerError
  LobForbiddenError: LobForbiddenError
  LobUnauthorizedError: LobUnauthorizedError

