app = require '../app.coffee'
module.exports = app

ctrlId = 0
app.controller 'rmapsProjectPinsCtrl', ($rootScope, $scope, $timeout, $log) ->
  ctrlId += 1
  $log = $log.spawn("map:projectPins")

  $scope.pinLimit = 4
  cancelIncrementing = false

  incrementPinLimit = () ->
    $timeout(() ->
      if $scope.pinLimit < $scope.pins.length && !cancelIncrementing
        $scope.pinLimit += 5
        incrementPinLimit()
    , 10)

  if $scope.pins?.length > 0
    incrementPinLimit()

  $rootScope.$on '$stateChangeStart', (toState) ->
    if toState.name != 'projectPins'
      cancelIncrementing = true
