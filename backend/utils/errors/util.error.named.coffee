PartiallyHandledError = require('./util.error.partiallyHandledError').PartiallyHandledError

class NamedError extends PartiallyHandledError
  constructor: (args...) ->
    rest = args.slice(1)
    super(rest...)
    @name = args[0]

module.exports = NamedError
