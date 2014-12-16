app = require '../../app.coffee'
require '../../runners/run-templates.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'
moment = require 'moment'

module.exports =
  app.controller 'SmallDetailsCtrl'.ourNs(), ['$scope', 'uiGmapLogger', ($scope, $log) ->
#      $log.error 'SmallDetailsCtrl, parameter changed'
    $scope.street_address_num = String.orNA $scope.parameter.street_address_num
    $scope.street_address_name = String.orNA $scope.parameter.street_address_name
    $scope.beds_total = String.orNA $scope.parameter.beds_total
    $scope.baths_total= String.orNA $scope.parameter.baths_total
    $scope.price =  String.orNA if $scope.parameter.price then casing.upper numeral($scope.parameter.price).format('0.00a'), '.' else null
    $scope.year_built = if $scope.parameter.year_built then moment($scope.parameter.year_built).format('YYYY') else String.orNA $scope.parameter.year_built
    $scope.acres = String.orNA $scope.parameter.acres
    , true
  ]