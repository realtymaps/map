_ = require 'lodash'
config = require './config'
colorWrap = require 'color-wrap'
baselogger = require './baselogger'
debug = require 'debug'
debug.enable(config.LOGGING.ENABLE)


_utils = ['functions', 'infoRoute', 'profilers', 'rewriters', 'transports', 'exitOnError', 'stripColors', 'emitErrs', 'padLevels']
_levelFns = ['debug', 'info', 'warn', 'error', 'log']
LEVELS = {}
for val, key in _levelFns
  LEVELS[val] = key

_maybeExecLevel = (level, current, fn) ->
  fn() if level >= current

_isValidLogObject = (logObject) ->
  isValid = false
  return  isValid unless logObject
  for val in _levelFns
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
  for val in _levelFns
    newLogger[val] = if val == 'debug' then debugInstance else logObject[val]

  newLogger

class Logger
  constructor: (@baseLogObject) ->
    throw Error('internalLogger undefined') unless @baseLogObject
    throw Error('@baseLogObject is invalid') unless _isValidLogObject @baseLogObject
    logFns = {}

    for level in _levelFns
      do (level) =>
        logFns[level] = (msg) =>
          _maybeExecLevel LEVELS[level], @currentLevel, =>
            @baseLogObject[level](msg)
        @[level] = logFns[level]

    for util in _utils
      do (util) =>
        if @baseLogObject.hasOwnProperty(util)
          if _.isFunction(@baseLogObject[util])
            @[util] = @baseLogObject[util].bind(@baseLogObject)
          else
            @[util] = @baseLogObject[util]

    @LEVELS = LEVELS
    @currentLevel = LEVELS.error

  spawn: (newInternalLoggerOrNS) =>
    if typeof newInternalLoggerOrNS is 'string'
      throw Error('@baseLogObject is invalid') unless _isValidLogObject @baseLogObject
      unless debug
        throw Error("cannot create '#{newInternalLoggerOrNS}' logging namespace - unable to find valid debug library")
      return _wrapDebug newInternalLoggerOrNS, @baseLogObject

    new Logger(newInternalLoggerOrNS or baseLogger)

logger = new Logger(baselogger)

module.exports = logger
