#controller responsible for delegating map drawing (map-control) actions
#mapDrawingCtrl
app = require '../app.coffee'

module.exports =
  app.controller 'MapDrawingCtrl'.ourNs(), [
    '$scope', '$emit', 'events'.ourNs(),
    ($scope, $emit, events) ->

      angular.extend $scope,
        clearDrawnPolysClick: ->
          $emit events.map.drawPolys.clear

        queryDrawnPolysClick: ->
          $emit events.map.drawPolys.need

        enableDrawnPolysClick: ->
          $scope.danger = !$scope.danger
          $emit events.map.drawPolys.isEnabled, $scope.danger

        enableDisableText: 'disabled'
        danger: false
  ]