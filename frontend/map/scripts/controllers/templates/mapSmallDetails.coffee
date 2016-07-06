app = require '../../app.coffee'
module.exports = app

app.controller 'rmapsSmallDetailsCtrl', ($scope, $log, rmapsResultsFormatterService, rmapsPropertyFormatterService) ->
  $log = $log.spawn 'rmapsSmallDetailsCtrl'
  $log.debug $scope.model

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  $scope.property = _.cloneDeep $scope.model

  if $scope.property.grouped
    # Uncomment to test parcel with multiple addresses
    # $scope.property.grouped.properties[0].address.street = '123 Main St'
    if _.uniq(_.pluck($scope.property.grouped.properties, 'address.street')).length > 1
      $scope.showAllAddresses = true

  $scope.addressComparator = (p) ->
    unit = p.address.unit
    while "#{unit}".length < 10
      unit = "0#{unit}"
    "#{p.address.street}#{unit}"
