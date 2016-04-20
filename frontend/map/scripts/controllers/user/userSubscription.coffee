app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserSubscriptionCtrl', ($rootScope, $scope, $log) ->
  $log = $log.spawn("map:userSubscription")
  console.log "$rootScope.user:\n#{JSON.stringify($rootScope.user, null, 2)}"
