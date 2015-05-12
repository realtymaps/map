app = require '../app.coffee'

app.constant('rmapsLogglyToken', 'rmapsLogglyMap')
.config [ 'LogglyLoggerProvider', 'rmapsLogglyToken', 'rmapsMainOptions',
(LogglyLoggerProvider, rmapsLogglyToken, rmapsMainOptions) ->
  LogglyLoggerProvider
  .level(rmapsMainOptions.map.options.logLevel.toUpperCase())
  .inputToken(rmapsLogglyToken)
  .includeTimestamp(true)
  .includeUrl(true)
  .sendConsoleErrors(true)
  .logToConsole true
]
