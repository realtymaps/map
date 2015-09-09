app = require '../app.coffee'
app.controller 'rmapsFavoritesCtrl', ($scope) ->

  $scope.activeView = 'favorites'

  $scope.favorites = {}

  #TODO: This probably should be coming from a favorites service as we (may or may not) want all favorites.
  #Where currently this only shows all favorites within the bounds of the map / filterSummary query.
  $scope.$watch 'map.markers.filterSummary', (newVal, oldVal) ->
    return if newVal == oldVal or !_.keys(newVal).length

    for id, entity of newVal
      if entity?.savedDetails?.isSaved
        $scope.favorites[id] = entity
