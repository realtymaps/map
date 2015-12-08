app = require '../app.coffee'

module.exports = app

app.controller 'swipeTrayCtrl', ($scope, $log) ->
  $log.debug "swipeTrayCtrl"

  $scope.index = 0

  $scope.trayPosition = ($index) ->
    console.log "trayPosition(#{$index})"

    if $index == $scope.index
      return 'tray-center'
    else if $index == ($scope.index + 1)
      return 'tray-right'
    else if $index == ($scope.index - 1)
      return 'tray-left'
    else if $index > $scope.index
      return 'hidden-right'
    else
      return 'hidden-left'

  $scope.swipeLeft = () ->
    $log.debug "Swipe Left"

    idx = $scope.index + 1
    if idx >= $scope.formatters.results.getResultsArray()?.length
      idx = $scope.formatters.results.getResultsArray()?.length - 1

    $scope.index = idx

  $scope.swipeRight = () ->
    $log.debug "Swipe Right"

    idx = $scope.index - 1
    if idx < 0
      idx = 0

    $scope.index = idx

  $scope.cardClick = ($index, property) ->
    $log.debug "Card Click"

    if $index > $scope.index
      $scope.index = $scope.index + 1
    else if $index < $scope.index
      $scope.index = $scope.index - 1

