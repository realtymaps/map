VError = require 'verror'
uuid = require 'node-uuid'
logger = require '../../config/logger'
analyzeValue = require '../../../common/utils/util.analyzeValue'

# If the first argument passed is an Error object, a uuid reference will be logged along with the stack trace
#   The uuid reference will also be appended to the message so the user will hopefully see it
class PartiallyHandledError extends VError
  constructor: (args...) ->
    super(args...)
    @name = 'PartiallyHandledError'
    if !@quiet && @jse_cause && !(@jse_cause instanceof PartiallyHandledError)
      ref = uuid.v1() # timestamp-based uuid
      @message = @message + " (Error reference #{ref})"
      logger.error analyzeValue.getSimpleDetails(@)

class QuietlyHandledError extends PartiallyHandledError
  constructor: (args...) ->
    @quiet = true
    super(args...)
    @name = 'QuietlyHandledError'


isUnhandled = (err) ->
  !err? || !(err instanceof PartiallyHandledError)


isCausedBy = (errorType, _err) ->
  check = (err) ->
    return getRootCause(err) instanceof errorType
  if _err
    return check(_err)
  else
    return check


getRootCause = (err) ->
  cause = err
  while cause instanceof PartiallyHandledError
    cause = cause.jse_cause
  return cause


module.exports = {
  PartiallyHandledError
  QuietlyHandledError
  isUnhandled
  isCausedBy
  getRootCause
}
