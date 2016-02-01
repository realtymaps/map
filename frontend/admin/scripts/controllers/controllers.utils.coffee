app = require '../app.coffee'

app.controller 'rmapsUtilsCtrl', ($scope) ->

app.controller 'rmapsUtilsFipsCodesCtrl', ($scope, rmapsFipsCodesService) ->

  $scope.$watch 'location.usStateCode', (usStateCode) ->
    return unless usStateCode

    rmapsFipsCodesService.getAllByState usStateCode
    .then (counties) ->
      $scope.counties = counties
