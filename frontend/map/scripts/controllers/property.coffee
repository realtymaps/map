app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsPropertyCtrl', ($scope, $stateParams, $log, rmapsPropertiesService, rmapsFormattersService, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsGoogleService) ->
  $log.debug "rmapsPropertyCtrl for id: #{$stateParams.id}"

  _.extend $scope, rmapsFormattersService.Common
  _.extend $scope, google: rmapsGoogleService

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  _.merge @scope,
    streetViewPanorama:
      status: 'OK'
    control: {}

  getPropertyDetail = (propertyId) ->
    $log.debug "Getting property detail for #{propertyId}"
    rmapsPropertiesService.getProperties propertyId, 'detail'
    .then (result) ->
      $log.debug "Have results for property detail for id #{propertyId}"
      $scope.selectedResult = result.data[0]

  getPropertyDetail $stateParams.id

  return
