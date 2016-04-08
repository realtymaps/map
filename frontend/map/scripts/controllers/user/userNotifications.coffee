app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserNotificationsCtrl', ($scope, $log) ->
  $log = $log.spawn("map:userNotifications")
