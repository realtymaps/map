app = require '../app.coffee'
module.exports = app

app.controller 'rmapsUserBillingCtrl', ($scope, $log) ->
  $log = $log.spawn("map:userBilling")
