_ = require 'lodash'
VError = require 'verror'
uuid = require 'node-uuid'
logger = require('../../config/logger').spawn('util:error:partiallyHandledError')
analyzeValue = require '../../../common/utils/util.analyzeValue'


# If the first argument passed is an Error object, a uuid reference will be logged along with the stack trace
#   The uuid reference will also be appended to the message so the user will hopefully see it
class PartiallyHandledError extends VError
  constructor: (args...) ->
    name = 'PartiallyHandledError'
    if typeof(args[0]) == 'string' && args.length > 1
      name = args.shift()
    if typeof(args[0]) == 'object' && Object.keys(args[0]).length == 1 && ('quiet' of args[0])
      @quiet = args[0].quiet
      args.shift()
    super(args...)
    @name = name
    if @jse_cause?.quiet
      @quiet ?= true
    if !(@jse_cause instanceof PartiallyHandledError)
      @message = @message + " (Error reference #{uuid.v1()})"
    if !@quiet
      @logReference()

  logReference: () ->
    logger.error analyzeValue.getFullDetails(@)

class QuietlyHandledError extends PartiallyHandledError
  constructor: (args...) ->
    @quiet = true
    name = 'QuietlyHandledError'
    if typeof(args[0]) == 'string' && args.length > 1
      name = args.shift()
    if typeof(args[0]) == 'object' && Object.keys(args[0]).length == 1 && ('quiet' of args[0])
      args.shift()
    super(name, args...)


isUnhandled = (err) ->
  !err? || !(err instanceof PartiallyHandledError)


isKnexUndefined = (err) ->
  err? && (err instanceof Error) && /Undefined binding\(s\) detected when compiling.*/.test(err.message)


isCausedBy = (errorType, _err) ->
  check = (err) ->
    cause = err
    while !(cause instanceof errorType) && cause instanceof PartiallyHandledError && cause.jse_cause?
      cause = cause.jse_cause
    return cause instanceof errorType
  if _err
    return check(_err)
  else
    return check


getRootCause = (err) ->
  cause = err
  while cause instanceof PartiallyHandledError && cause.jse_cause?
    cause = cause.jse_cause
  return cause


module.exports = {
  PartiallyHandledError
  QuietlyHandledError
  isUnhandled
  isCausedBy
  getRootCause
  isKnexUndefined
}
