NamedError = require('./util.error.named')

class PayloadError extends NamedError
  constructor: (@payload, name, args...) ->
    super(name, args...)

module.exports = PayloadError
