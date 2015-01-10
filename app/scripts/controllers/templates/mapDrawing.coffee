#controller responsible for delegating map drawing (map-control) actions
#mapDrawingCtrl
app = require '../../app.coffee'

module.exports =
  app.controller 'MapDrawingCtrl'.ourNs(), [
    '$scope', '$rootScope', 'events'.ourNs(),
    ($scope, $rootScope, Events) ->

      angular.extend $scope,
        clearDrawnPolysClick: ->
          $rootScope.$emit Events.map.drawPolys.clear

        queryDrawnPolysClick: ->
          $rootScope.$emit Events.map.drawPolys.query

        enableDrawnPolysClick: ->
          $scope.danger = !$scope.danger
          $scope.enableDisableText = if $scope.danger then 'draw enabled' else 'draw disabled'
          $rootScope.$emit Events.map.drawPolys.isEnabled, $scope.danger

        enableDisableText: 'draw disabled'
        danger: false
  ]