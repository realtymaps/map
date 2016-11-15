NamedError = require './util.error.named'

class NoResults extends NamedError
  constructor: (@row, args...) ->
    super('NoResults', args...)
    @quiet = true

class Message extends NamedError
  constructor: (@row, args...) ->
    super('Message', args...)

class HasRawError extends NamedError
  constructor: (@row, args...) ->
    super('HasRawError', args...)

class NormalizeError extends NamedError
  constructor: (@row, args...) ->
    super('NormalizeError', args...)

module.exports = {
  NoResults
  Message
  HasRawError
  NormalizeError
}
