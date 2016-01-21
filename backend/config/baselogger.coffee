winston = require('winston')
fs = require('fs')
stackTrace = require('stack-trace')
path = require 'path'
cluster = require 'cluster'
colorWrap = require 'color-wrap'
config = require('./config')
logPath = config.LOGGING.PATH
_ = require 'lodash'

if !fs.existsSync(logPath)
  fs.openSync(logPath, 'w')

myCustomLevels =
  levels:
    debug: 0
    info: 1
    warn: 2
    error: 3

  colors:
    route: 'grey'
    sql: 'magenta'
    debug: 'cyan'
    info: 'green'
    warn: 'yellow'
    error: 'red'

# console.info config.LOGGING.LEVEL
logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)
      level: config.LOGGING.LEVEL
      colorize: true
      timestamp: true
    new (winston.transports.File)
      filename: logPath
      level: config.LOGGING.LEVEL
      timestamp: true
  ]
  levels: myCustomLevels.levels
)
winston.addColors myCustomLevels.colors


getFileAndLine = (trace, index, extension = '.coffee') ->
  filename: path.basename(trace[index].getFileName(), extension)
  lineNumber: trace[index].getLineNumber()

if config.LOGGING.FILE_AND_LINE
  for own level of myCustomLevels.levels
    oldFunc = logger[level]
    do (oldFunc) ->
      logger[level] = () ->
        trace = stackTrace.parse(new Error())  # this gets correct coffee line, where stackTrace.get() does not
        args = Array.prototype.slice.call(arguments)
        info = getFileAndLine(trace, 4)
        if info.lineNumber == 18 && info.filename == 'index.js'
          info = getFileAndLine(trace, 5)
        if info.filename.endsWith('.js')
          info = getFileAndLine(trace, 1)
        decorator = "[#{info.filename}:#{info.lineNumber}]"
        if cluster.worker?.id?
          decorator = "<#{cluster.worker.id}>#{decorator}"
        args.unshift(decorator)
        oldFunc.apply(logger, args)


logger.debug 'Log Levels: %j', logger.levels, {}
logger.debug 'Log Transport Levels: %j', _.map(logger.transports, (t) -> t.level), {}

colorWrap logger, myCustomLevels.levels


module.exports = logger
