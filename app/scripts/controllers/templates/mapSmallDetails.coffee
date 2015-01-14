app = require '../../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'
moment = require 'moment'


module.exports =
  app.controller 'MapSmallDetailsCtrl'.ourNs(), ['$scope', 'Logger'.ourNs(), 'ParcelEnums'.ourNs(), ($scope, $log, ParcelEnums) ->
    colorClasses = {}
    colorClasses[ParcelEnums.status.sold] = 'label-sold-property'
    colorClasses[ParcelEnums.status.pending] = 'label-pending-property'
    colorClasses[ParcelEnums.status.forSale] = 'label-sale-property'
    colorClasses[ParcelEnums.status.notForSale] = 'label-notsale-property'

    getPrice = (val) ->
      String.orNA if val then casing.upper numeral(val).format('0,0'), ',' else null
    getStatusClass = (status) ->
      return colorClasses[status] || ''

    $scope.street_address_num = String.orNA $scope.parameter.street_address_num
    $scope.street_address_name = String.orNA $scope.parameter.street_address_name
    $scope.beds_total = String.orNA $scope.parameter.bedrooms
    $scope.baths_full = String.orNA $scope.parameter.baths_full
    $scope.baths_half= String.orNA $scope.parameter.baths_half
    $scope.baths_total= String.orNA $scope.parameter.baths_total
    $scope.finished_sqft= String.orNA $scope.parameter.finished_sqft
    $scope.price = getPrice $scope.parameter.price
    $scope.local_assessed_value = getPrice $scope.parameter.local_assessed_value
    $scope.year_built = if $scope.parameter.year_built then moment($scope.parameter.year_built).format('YYYY') else String.orNA $scope.parameter.year_built
    $scope.acres = String.orNA $scope.parameter.acres
    $scope.rm_status = String.orNA $scope.parameter.rm_status
    $scope.owner_name = String.orNA $scope.parameter.owner_name
    $scope.owner_name2 = $scope.parameter.owner_name2
    
    $scope.statusClass = getStatusClass($scope.parameter.rm_status)
  ]
