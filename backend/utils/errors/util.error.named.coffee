PartiallyHandledError = require('./util.error.partiallyHandledError').PartiallyHandledError

class NamedError extends PartiallyHandledError
  constructor: (name, args...) ->
    super(args...)
    # this has to execute after the constructor for proper functioning
    @name = name

module.exports = NamedError
