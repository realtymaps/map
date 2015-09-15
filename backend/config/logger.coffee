winston = require('winston')
fs = require('fs')
stackTrace = require('stack-trace')
path = require 'path'
cluster = require 'cluster'

config = require('./config')
logPath = config.LOGGING.PATH
_ = require 'lodash'

if !fs.existsSync(logPath)
  fs.openSync(logPath, 'w')

myCustomLevels =
  levels:
    route: 0
    sql: 1
    debug: 2
    info: 3
    warn: 4
    error: 5

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


if config.LOGGING.FILE_AND_LINE
  for own level of myCustomLevels.levels
    oldFunc = logger[level]
    do (oldFunc) ->
      logger[level] = () ->
        trace = stackTrace.get()
        args = Array.prototype.slice.call(arguments)
        filename = path.basename(trace[1].getFileName(), '.coffee')
        decorator = "[#{filename}:#{trace[1].getLineNumber()}]"
        if cluster.worker?.id?
          decorator = "<#{cluster.worker.id}>#{decorator}"
        args.unshift(decorator)
        oldFunc.apply(logger, args)


unless logger.infoRoute
  logger.infoRoute = (name, route) ->
    logger.route "Route #{name} of: '#{route}' set"

logger.log 'debug', 'Log Levels: %j', logger.levels, {}
logger.log 'debug', 'Log Transport Levels: %j', _.map(logger.transports, (t) -> t.level), {}

module.exports = logger
