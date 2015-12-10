app = require '../app.coffee'

module.exports = app

app.controller 'swipeTrayCtrl', ($scope, $log) ->
  $log.debug "swipeTrayCtrl"

  $scope.index = 0

  $scope.trayPosition = ($index) ->
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

    checkLoadMore()

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
      checkLoadMore()
    else if $index < $scope.index
      $scope.index = $scope.index - 1

  # Reset the index to 0 if the available properties in the scope have changed
  $scope.$watch 'map.markers.filterSummary', (newVal, oldVal) =>
    $log.debug 'swipeTrayCtrl - watch filterSummary'
    return if newVal == oldVal

    $scope.index = 0

  checkLoadMore = () ->
    if $scope.index >= $scope.resultsLimit - 2
      $log.debug 'Swipe Tray - call loadMore()'
      $scope.formatters.results.loadMore()

