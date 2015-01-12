app = require '../app.coffee'

loadingCount = 0

app.service 'Spinner'.ourNs(), [ 'Logger'.ourNs(), ($log) ->
  incrementLoadingCount: (logMessage, delta=1) ->
    ++loadingCount
    #$log.debug("incremented loadingCount by #{delta} (#{logMessage}): #{loadingCount}")
  decrementLoadingCount: (logMessage, delta=1) ->
    --loadingCount
    #$log.debug("decremented loadingCount by #{delta} (#{logMessage}): #{loadingCount}")
  getLoadingCount: () ->
    loadingCount
]
