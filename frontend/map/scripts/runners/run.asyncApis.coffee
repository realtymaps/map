#angularLoad is a service so it can only be run at app.run
app = require '../app.coffee'

app.run ($q, $log,  angularLoad, rmapsAsyncAPIsService) ->
  $log = $log.spawn("frontend:maps:rmapsAsyncAPIsRunner")
  rmapsAsyncAPIsService.getAll()
  .then (urls) ->
    promises = urls.map (url) ->
      angularLoad.loadScript url

    $q.all(promises)
    .then (result) ->
      rmapsAsyncAPIsService.getDeferred().resolve(result)
      $log.debug "all libs loaded asynchronously"
    .catch (err) ->
      $log.error err
