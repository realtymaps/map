VError = require 'verror'

class PartiallyHandledError extends VError
  constructor: (args...) ->
    super(args...)
    @name = 'PartiallyHandledError'
  
model.exports =
  PartiallyHandledError: PartiallyHandledError
  isUnhandled: (err) ->
    !(err instanceof PartiallyHandledError)
