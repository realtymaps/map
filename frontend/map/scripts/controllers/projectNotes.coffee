app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectNotesCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectNotes")
