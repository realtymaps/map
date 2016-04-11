app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsUserPaymentHistoryCtrl', ($scope, $log, rmapsChargesService) ->
  $log = $log.spawn("map:userPaymentHistory")

  $scope.charges = null
  $scope.sortField = 'created'
  $scope.sortReverse = true


  rmapsChargesService.get()
  .then (charges) ->
    console.log "charges:\n#{JSON.stringify(charges,null,2)}"
    $scope.charges = charges
