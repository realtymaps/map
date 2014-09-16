app = require '../app.coffee'

app.factory 'MapOptions'.ourNs(), [
  'Logger'.ns(), '$http', '$timeout', '$q',
  'Limits'.ourNs(), 'User'.ourNs()
  ($log, $http, $timeout, $q,
  Limits, User) ->
    all = $q.all([Limits,User])
    all.then((data) ->
      $log.info "options: " + data
      mapOptions = data.reduce (prev,current) ->
        options = prev?.map or {}
        current = current?.map or {}
        _.merge options, current
    )
  ]
