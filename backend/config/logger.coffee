winston = require('winston')
fs = require('fs')
stackTrace = require('stack-trace')
path = require 'path'

config = require('./config')
logPath = config.LOGGING.PATH

if !fs.existsSync(logPath)
  fs.openSync(logPath, 'w')

myCustomLevels =
  levels:
    debug: 0
    info: 1
    warn: 2
    error: 3

  colors:
    debug: 'grey'
    info: 'green'
    warn: 'orange'
    error: 'red'


logger = new (winston.Logger)
  transports: [
    new (winston.transports.Console)
      level: config.LOGGING.LEVEL
      colorize: true
      timestamp: true
    new (winston.transports.File)
      filename: logPath
      level: config.LOGGING.LEVEL
      timestamp: true
  ],
  levels: myCustomLevels.levels

winston.addColors myCustomLevels.colors

if config.LOGGING.FILE_AND_LINE
  for own level of myCustomLevels.levels
    oldFunc = logger[level]
    do (oldFunc) ->
      logger[level] = () ->
        trace = stackTrace.get()
        args = Array.prototype.slice.call(arguments)
        filename = path.basename(trace[1].getFileName(), '.coffee')
        args.unshift("[#{filename}:#{trace[1].getLineNumber()}]")
        oldFunc.apply(logger, args)


logger.info "Logger configured"


module.exports = logger
