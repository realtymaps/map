partial = require('./util.error.partiallyHandledError')

class CurrentProfileError extends partial.PartiallyHandledError
  constructor: (args...) ->
    super('CurrentProfileError', args...)
    @returnStatus = status.BAD_REQUEST

class NoProfileFoundError extends partial.PartiallyHandledError
  constructor: (args...) ->
    super('NoProfileFoundError', args...)
    @returnStatus = status.BAD_REQUEST

module.exports = {
  CurrentProfileError
  NoProfileFoundError
}
