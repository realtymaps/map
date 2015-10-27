NamedError = require './util.error.named'

module.exports =
  IsIdObjError:
    class IsIdObjError extends NamedError
      constructor: (args...) ->
        super('IsIdObjError', args...)
