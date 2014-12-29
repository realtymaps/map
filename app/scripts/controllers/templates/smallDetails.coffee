app = require '../../app.coffee'
require '../../runners/run-templates.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'
moment = require 'moment'

module.exports =
  app.controller 'SmallDetailsCtrl'.ourNs(), ['$scope', 'Logger'.ourNs(), ($scope, $log) ->
    getPrice = (val) ->
      String.orNA if val then casing.upper numeral(val).format('0.00a'), '.' else null

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
    , true
  ]
