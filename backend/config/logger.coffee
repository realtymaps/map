baselogger = require './baselogger'
debug = require 'debug'

_fns = ['debug', 'info', 'warn', 'error', 'log']
LEVELS = {}
for val, key in _fns
  LEVELS[val] = key

_maybeExecLevel = (level, current, fn) ->
  fn() if level >= current

_isValidLogObject = (logObject) ->
  isValid = false
  return  isValid unless logObject
  for val in _fns
    isValid = logObject[val]? and typeof logObject[val] is 'function'
    break unless isValid
  isValid

###
  Overide logObject.debug with a debug instance
  see: https://github.com/visionmedia/debug/blob/master/Readme.md
###
_wrapDebug = (debugNS, logObject) ->
  # define a new debug NS (which is to be used as handle for controlling logging verbosity)
  debugInstance = debug(debugNS)
  newLogger = {}
  # for val in _fns
  #   newLogger[val] = if val == 'debug' then debugInstance else logObject[val]

  for val in _fns
    newLogger[val] = (msg) -> debugInstance(logObject[val](msg))

  newLogger

class Logger
  constructor: (@baseLogObject) ->
    console.log "\n\n#### Logger instantiated"
    throw 'internalLogger undefined' unless @baseLogObject
    throw '@$log is invalid' unless _isValidLogObject @baseLogObject
    @doLog = true
    logFns = {}

    for level in _fns
      do (level) =>
        logFns[level] = (msg) =>
          if @doLog
            _maybeExecLevel LEVELS[level], @currentLevel, =>
              @$log[level](msg)
        @[level] = logFns[level]

    @LEVELS = LEVELS
    @currentLevel = LEVELS.error

  spawn: (newInternalLoggerOrNS) =>
    console.log "\n\n#### spawning logger #{newInternalLoggerOrNS}"
    if typeof newInternalLoggerOrNS is 'string'
      throw '@baseLogObject is invalid' unless _isValidLogObject @baseLogObject
      unless debug
        throw "cannot create '#{newInternalLoggerOrNS}' logging namespace - unable to find valid debug library"
      return _wrapDebug newInternalLoggerOrNS, @baseLogObject

    new Logger(newInternalLoggerOrNS or baseLogger)


module.exports = new Logger(baselogger)
