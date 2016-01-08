app = require '../app.coffee'

app.controller 'rmapsUtilsCtrl', ($scope) ->
  
app.controller 'rmapsUtilsFipsCodesCtrl', ($scope, rmapsFipsCodes) ->

  $scope.$watch 'location.usStateCode', (usStateCode) ->
    return unless usStateCode

    rmapsFipsCodes.getAllByState usStateCode
    .then (counties) ->
      $scope.counties = counties
