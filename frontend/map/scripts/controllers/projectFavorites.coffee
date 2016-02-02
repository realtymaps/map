app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectFavoritesCtrl', ($scope, $log) ->
  $log = $log.spawn("map:projectFavorites")
