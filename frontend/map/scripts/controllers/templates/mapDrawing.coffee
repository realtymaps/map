#controller responsible for delegating map drawing (map-control) actions
#mapDrawingCtrl
app = require '../../app.coffee'

module.exports =
  app.controller 'rmapsMapDrawingCtrl', ($scope, $rootScope, rmapsevents) ->

      angular.extend $scope,
        clearDrawnPolysClick: ->
          $rootScope.$emit rmapsevents.map.drawPolys.clear

        queryDrawnPolysClick: ->
          $rootScope.$emit rmapsevents.map.drawPolys.query

        enableDrawnPolysClick: ->
          $scope.danger = !$scope.danger
          $scope.enableDisableText = if $scope.danger then 'draw enabled' else 'draw disabled'
          $rootScope.$emit rmapsevents.map.drawPolys.isEnabled, $scope.danger

        enableDisableText: 'draw disabled'
        danger: false