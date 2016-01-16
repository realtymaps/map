NamedError = require '../util.error.named'
PayloadError = require '../util.error.payload'

generator = (errorTypes, factory) ->
  errors = {}

  for name in errorTypes
    do (name) ->
      name = name + 'Error'
      errors[name] = factory(name)
  errors

namedFactory = (name) ->
  class WrappedError extends NamedError
    constructor: (args...) ->
      super(name, args...)

payloadFactory = (name) ->
  class WrappedError extends PayloadError
    constructor: (payload, args...) ->
      super(payload, name, args...)

module.exports = do ->

  named: (errorTypes) ->
    generator(errorTypes, namedFactory)

  payload: (errorTypes) ->
    generator(errorTypes, payloadFactory)
