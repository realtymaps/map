app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectPinsCtrl', ($rootScope, $scope, $timeout, $log) ->
  $log = $log.spawn("map:projectPins")

  $scope.pinLimit = 4
  cancelIncrementing = false

  incrementLimit = () ->
    $timeout(() ->
      if $scope.pinLimit < $scope.pins.length && !cancelIncrementing
        $scope.pinLimit += 5
        incrementLimit()
    , 10)

  if $scope.pins?.length > 0
    incrementLimit()

  $rootScope.$on '$stateChangeStart', (toState) ->
    if toState.name != 'projectPins'
      cancelIncrementing = true
