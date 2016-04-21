class UnhandledNamedError extends Error
  constructor: (name, @message) ->
    super()
    # this has to execute after the constructor for proper functioning
    @name = name
    Error.captureStackTrace(this, UnhandledNamedError)

module.exports = UnhandledNamedError
