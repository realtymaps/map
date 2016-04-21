
###
  This error counts as unhandled as far as isUnhandled is concerned, and thus is appropriate to capture a very specific
  bit of detail error message before bring caught and rethrown later into a more coarse-grained PartiallyHandledError.
  For an example of its use pattern, see service.rets.coffee
###


class UnhandledNamedError extends Error
  constructor: (name, @message) ->
    super()
    # this has to execute after the constructor for proper functioning
    @name = name
    Error.captureStackTrace(this, UnhandledNamedError)

module.exports = UnhandledNamedError
