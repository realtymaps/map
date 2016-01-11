NamedError = require '../util.error.named'

module.exports = (errorTypes) ->
  errors = {}

  for name in errorTypes
    do (name) ->
      name = name + 'Error'
      errors[name] = class WrappedError extends NamedError
        constructor: (args...) ->
          super(name, args...)
  errors
