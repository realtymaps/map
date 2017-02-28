VError = require 'verror'
uuid = require 'node-uuid'
logger = require('../../config/logger').spawn('util:error:partiallyHandledError')
analyzeValue = require '../../../common/utils/util.analyzeValue'
status = require '../../../common/utils/httpStatus'
_ = require 'lodash'


# it's an options object if it only contains allowed keys
_isOptions = (opts) ->
  if Object.keys(opts).length == 0
    return false
  for key of opts
    if !(key in ['quiet', 'returnStatus', 'expected'])
      return false
  return true


# If the first argument passed is an Error object, a uuid reference will be logged along with the stack trace
#   The uuid reference will also be appended to the message so the user will hopefully see it
class PartiallyHandledError extends VError
  constructor: (args...) ->
    name = 'PartiallyHandledError'
    if typeof(args[0]) == 'string' && args.length > 1
      name = args.shift()
    for i in [0...args.length]
      if typeof(args[i]) == 'object' && _isOptions(args[i])
        _.extend(@, args[i])
        args.splice(i,1)
    super(args...)
    @name = name
    @returnStatus ?= (@jse_cause?.returnStatus ? status.INTERNAL_SERVER_ERROR)
    if @jse_cause?.quiet
      @quiet ?= true
    if @jse_cause instanceof PartiallyHandledError
      @errorRef = @jse_cause.errorRef
    else
      @errorRef = uuid.v1()
      @message = @message + " (Error reference #{@errorRef})"
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
    if typeof(args[0]) == 'object' && _isOptions(args[0])
      _.extend(@, args[0])
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
