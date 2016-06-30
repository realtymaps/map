app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectFavoritesCtrl', ($rootScope, $scope, $timeout, $log) ->
  $log = $log.spawn("map:projectFavorites")

  $scope.favoriteLimit = 4
  cancelIncrementing = false

  incrementLimit = () ->
    $timeout(() ->
      if $scope.favoriteLimit < $scope.favorites.length && !cancelIncrementing
        $scope.favoriteLimit += 5
        incrementLimit()
    , 10)

  if $scope.favorites?.length > 0
    incrementLimit()

  $rootScope.$on '$stateChangeStart', (toState) ->
    if toState.name != 'projectFavorites'
      cancelIncrementing = true
