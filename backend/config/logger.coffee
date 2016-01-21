_ = require 'lodash'
config = require './config'
colorWrap = require 'color-wrap'
baselogger = require './baselogger'
debug = require 'debug'
debug.enable(config.LOGGING.ENABLE)


_utils = ['functions', 'profilers', 'rewriters', 'transports', 'exitOnError', 'stripColors', 'emitErrs', 'padLevels']
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

    # delegation of both member funcs and member structs from this class to the baseLogObject
    for util in _utils
      do (util) =>
        if _.isFunction(@baseLogObject[util])
          @[util] = (args...) ->
            return @baseLogObject[util](args...)
        else
          Object.defineProperty @, util,
            get: () =>
              return @baseLogObject[util]
            set: (value) =>
              @baseLogObject[util] = value
            enumerable: false,
            # writable: true
            # value: 'static'

    @LEVELS = LEVELS
    @currentLevel = LEVELS[config.LOGGING.LEVEL]

  spawn: (newInternalLoggerOrNS) =>
    if typeof newInternalLoggerOrNS is 'string'
      throw Error('@baseLogObject is invalid') unless _isValidLogObject @baseLogObject
      unless debug
        throw Error("cannot create '#{newInternalLoggerOrNS}' logging namespace - unable to find valid debug library")
      # TODO: the 3 lines below can be replaced (once my PR gets merged to color-wrap) with:
      # TODO: return colorWrap(_wrapDebug(newInternalLoggerOrNS, @baseLogObject), ['debug'])
      newLogger = _wrapDebug(newInternalLoggerOrNS, @baseLogObject)
      colorWrap(newLogger, ['debug'])
      return newLogger
    # TODO: the 3 lines below can be replaced (once my PR gets merged to color-wrap) with:
    # TODO: colorWrap(new Logger(newInternalLoggerOrNS or baseLogger), ['debug'])
    newLogger = new Logger(newInternalLoggerOrNS or baseLogger)
    colorWrap(newLogger, ['debug'])
    newLogger

# TODO: the 3 lines below can be replaced (once my PR gets merged to color-wrap) with:
# TODO: module.exports = colorWrap(new Logger(baselogger))

logger = new Logger(baselogger).spawn('__OMGWTFBBQ____YOU_SHOULD_BE_USING_SPAWN____OMGWTFBBQ__')

colorWrap(logger)

module.exports = logger
