app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserTeamMembersCtrl', ($scope, $log) ->
  $log = $log.spawn("map:userTeamMembers")
