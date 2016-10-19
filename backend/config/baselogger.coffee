winston = require('winston')
fs = require('fs')
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
    debug: 'cyan'
    info: 'green'
    warn: ['yellow', 'bold']
    error: ['red', 'bold']

consoleTransport = new (winston.transports.Console)
  level: config.LOGGING.LEVEL
  colorize: true
  timestamp: config.LOGGING.TIMESTAMP
fileTransport = new (winston.transports.File)
  filename: logPath
  level: config.LOGGING.LEVEL
  timestamp: true

transports = []
transports.push consoleTransport
if config.LOGGING.LOG_TO_FILE
  transports.push fileTransport

logger = new (winston.Logger)(
  transports: transports
  levels: myCustomLevels.levels
)
winston.addColors myCustomLevels.colors


#logger.debug 'Log Levels: %j', logger.levels, {}
#logger.debug 'Log Transport Levels: %j', _.map(logger.transports, (t) -> t.level), {}


module.exports = logger
