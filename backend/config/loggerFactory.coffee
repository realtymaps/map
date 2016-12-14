config = require './config'
colorWrap = require 'color-wrap'
baselogger = require './baselogger'
debug = require 'debug'
stackTrace = require('stack-trace')
cluster = require 'cluster'
path = require 'path'
memoize = require 'memoizee'


if !config.LOGGING.ENABLE
  debug.enable(process.env.DEBUG || null)
else
  names = config.LOGGING.ENABLE.split(/[, ]/g)
  for name,i in names
    if name.endsWith('*')
      continue
    else if name.endsWith(':')
      names[i] = name+'*'
    else
      names[i] = name+':*'
  names = names.concat((process.env.DEBUG||'').split(','))
  debug.enable(names.join(','))

# fixing it so we don't get redundant timestamps on prod
# https://github.com/visionmedia/debug/issues/161
debug.formatArgs = ()->
  if this.useColors
    arguments[0] = '  \u001b[9' + this.color + 'm' + this.namespace + ' ' + '\u001b[0m' + arguments[0]
  else
    arguments[0] = '  ' + this.namespace + ' ' + arguments[0]
  return arguments

_levelFns = ['info', 'warn', 'error']


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
    # this allows passing a function to be evaluated only if logging will take place
    if typeof(args[1]) == 'function'
      args[1] = args[1]()
    func.apply(bindThis, args)

_resolveOutput = (func, bindThis) ->
  (args...) ->
    # this allows passing a function to be evaluated only if logging will take place
    if typeof(args[0]) == 'function'
      args[0] = args[0]()
    func.apply(bindThis, args)

if !baselogger
  throw new Error('baselogger undefined')
if !_isValidLogObject(baselogger)
  throw new Error('baselogger is invalid')


# cache logger results so we get consistent coloring
_getLogger = (base, namespace) ->
  new Logger(base, namespace)
_getLogger = memoize(_getLogger, primitive: true)


class Logger
  constructor: (@base, @namespace) ->

    if !@namespace? || typeof @namespace != 'string'
      throw new Error('invalid logging namespace')

    if @namespace == ''
      augmentedNamespace = @base+':__default_namespace__:'
      forceDebugFileAndLine = true
    else
      if !@namespace.endsWith(':')
        @namespace += ':'
      augmentedNamespace = @base+':'+@namespace

    @level = config.LOGGING.LEVEL

    ###
      Override logObject.debug with a debug instance
      namespace is to be used as handle for controlling logging verbosity
      see: https://github.com/visionmedia/debug/blob/master/Readme.md
    ###
    debugInstance = debug(augmentedNamespace)
    if !debugInstance.enabled
      @debug = (() ->)
    else if forceDebugFileAndLine || config.LOGGING.FILE_AND_LINE
      @debug = _decorateOutput(debugInstance)
    else
      @debug = _resolveOutput(debugInstance)

    foundLevel = (@level == 'debug')
    for level in _levelFns
      if level == @level
        foundLevel = true
      if !foundLevel
        @[level] = (() ->)
      else if forceDebugFileAndLine || config.LOGGING.FILE_AND_LINE
        @[level] = _decorateOutput(baselogger[level], baselogger)
      else
        @[level] = _resolveOutput(baselogger[level], baselogger)

    ###
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
    ###

    colorWrap(@)

  spawn: (subNamespace) ->
    _getLogger(@base, @namespace+subNamespace)

  isEnabled: (subNamespace='') ->
    suffix = if subNamespace != '' && !subNamespace.endsWith(':') then ':' else ''
    debug.enabled(@namespace+subNamespace+suffix)

  debugQuery: (thing) ->
    @debug -> thing.toString()
    thing

module.exports = (base) ->
  _getLogger(base, '')
