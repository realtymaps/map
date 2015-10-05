app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsNotesCtrl', ($scope) ->
  $scope.activeView = 'notes'

app.controller 'rmapsMapNotesCtrl', ($scope, $http, $log) ->
  $log = $log.spawn("map:notes")

  $scope.notes = []

  notesPromise = $http.get(backendRoutes.notesSession.root)
  notesPromise.then ({data}) ->
    $log.debug "received note data #{data.length} " if data?.length
    $scope.notes = data
  notesPromise.error (error) ->
    $log.error error
