_ = require 'lodash'
config = require './config'
colorWrap = require 'color-wrap'
baselogger = require './baselogger'
debug = require 'debug'
debug.enable(config.LOGGING.ENABLE)
stackTrace = require('stack-trace')
cluster = require 'cluster'
path = require 'path'


_utils = ['functions', 'profilers', 'rewriters', 'transports', 'exitOnError', 'stripColors', 'emitErrs', 'padLevels']
_levelFns = ['info', 'warn', 'error', 'log']


_isValidLogObject = (logObject) ->
  if !logObject?
    return false
  for val in _levelFns
    if !logObject[val]? || typeof logObject[val] != 'function'
      return false
  return true

_getFileAndLine = (trace, index) ->
  fileinfo = path.parse(trace[index].getFileName())
  if fileinfo.name == 'index'
    filename = "#{path.basename(fileinfo.dir)}/index"
  else
    filename = fileinfo.name
  filename: filename
  lineNumber: trace[index].getLineNumber()

_decorateOutput = (func, bindThis) ->
  (args...) ->
    trace = stackTrace.parse(new Error())  # this gets correct coffee line, where stackTrace.get() does not
    info = _getFileAndLine(trace, 1)
    if info.filename == 'color-wrap/index'
      info = _getFileAndLine(trace, 2)
    decorator = "[#{info.filename}:#{info.lineNumber}]"
    if cluster.worker?.id?
      decorator = "<#{cluster.worker.id}>#{decorator}"
    args.unshift(decorator)
    func.apply(bindThis, args)


if !baselogger
  throw Error('internalLogger undefined')
if !_isValidLogObject(baselogger)
  throw Error('baselogger is invalid')


_debugCache = {}


class Logger
  constructor: (namespace, showDebugFileAndLine) ->

    if !namespace || typeof namespace != 'string'
      throw new Error('invalid logging namespace')

    # need to cache debugInstance in order to get consistent color; this could be considered a bug in the debug module
    if !_debugCache[namespace]?
      _debugCache[namespace] = debug(namespace)
    debugInstance = _debugCache[namespace]

    ###
      Overide logObject.debug with a debug instance
      namespace is to be used as handle for controlling logging verbosity
      see: https://github.com/visionmedia/debug/blob/master/Readme.md
    ###
    if showDebugFileAndLine
      @debug = _decorateOutput(debugInstance)
    else
      @debug = debugInstance

    for level in _levelFns
      if config.LOGGING.FILE_AND_LINE
        @[level] = _decorateOutput(baselogger[level], baselogger)
      else
        @[level] = baselogger[level].bind(baselogger)

    # delegation of both member funcs and member structs from this class to the baseLogObject
    for util in _utils
      do (util) =>
        if _.isFunction(baselogger[util])
          @[util] = baselogger[util].bind(baselogger)
        else
          Object.defineProperty @, util,
            get: () ->
              return baselogger[util]
            set: (value) ->
              baselogger[util] = value
            enumerable: false

    colorWrap(@)

  spawn: (args...) ->
    return new Logger(args...)

module.exports = new Logger("backend:__default_namespace__")
