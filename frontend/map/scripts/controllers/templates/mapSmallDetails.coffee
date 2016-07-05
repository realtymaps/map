app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsSmallDetailsCtrl', ($scope, $log, rmapsResultsFormatterService, rmapsPropertyFormatterService) ->
  $log = $log.spawn 'rmapsSmallDetailsCtrl'
  $log.debug $scope.model

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  $scope.property = _.cloneDeep $scope.model

  $scope.unitComparator = (unit) ->
    unit = unit.address.unit
    while "#{unit}".length < 10
      unit = "0#{unit}"
    unit

