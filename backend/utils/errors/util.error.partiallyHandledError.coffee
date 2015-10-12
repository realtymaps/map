VError = require 'verror'
uuid = require 'node-uuid'
logger = require '../../config/logger'

# If the first argument passed is an Error object, a uuid reference will be logged along with the stack trace
#   The uuid reference will also be appended to the message so the user will hopefully see it
class PartiallyHandledError extends VError
  constructor: (args...) ->
    super(args...)
    @name = 'PartiallyHandledError'
    if @.jse_cause && !(@.jse_cause instanceof PartiallyHandledError)
      ref = uuid.v1() # timestamp-based uuid
      logger.error "Error reference: #{ref}\nMessage: #{@message}\nStack: #{args[0].stack}"
      @message = @message + " (Error reference #{ref})"

module.exports =
  PartiallyHandledError: PartiallyHandledError
  isUnhandled: (err) ->
    !(err instanceof PartiallyHandledError)
  isCausedBy: (errorType) ->
    (err) ->
      if err instanceof errorType
        return true
      cause = err
      while cause instanceof PartiallyHandledError
        cause = cause.jse_cause
      return cause instanceof errorType
