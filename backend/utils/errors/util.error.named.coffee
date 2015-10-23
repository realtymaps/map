PartiallyHandledError = require('./util.error.partiallyHandledError').PartiallyHandledError

class NamedError extends PartiallyHandledError
  constructor: (@name, args...) ->
    super(args...)

module.exports = NamedError
