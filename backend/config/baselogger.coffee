winston = require('winston')
fs = require('fs')
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


#logger.debug 'Log Levels: %j', logger.levels, {}
#logger.debug 'Log Transport Levels: %j', _.map(logger.transports, (t) -> t.level), {}


module.exports = logger
