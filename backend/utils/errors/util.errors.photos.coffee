NamedError = require './util.error.named'

class HttpStatusCodeError extends NamedError
  constructor: (@statusCode, args...) ->
    super('HttpStatusCodeError', args...)

class BadContentTypeError extends NamedError
  constructor: (args...) ->
    super('BadContentTypeError', args...)

module.exports = {
  HttpStatusCodeError
  BadContentTypeError
}
