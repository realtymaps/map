NamedError = require('./util.error.named')

class ExpectedSingleRowError extends NamedError
  constructor: (args...) ->
    super('ExpectedSingleRowError', args...)


module.exports = ExpectedSingleRowError
