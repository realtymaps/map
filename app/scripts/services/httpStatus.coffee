app = require '../app.coffee'

httpStatus = require '../../../common/utils/httpStatus.coffee'
#console.debug 'httpStatus: ' + httpStatus

app.service 'HttpStatus'.ourNs(), [
  'Logger'.ns(), ($log) ->
    $log.info 'httpStatus: ' + httpStatus
    httpStatus
 ]
