NamedError = require './util.error.named'

errors = {}

errorTypes = [
  'IsIdObj'
  'MissingVar'
  'UpdateFailed'
]

for name in errorTypes
  do (name) ->
    name = name + 'Error'
    errors[name] = class WrappedError extends NamedError
      constructor: (args...) ->
        super(name, args...)

module.exports = errors
