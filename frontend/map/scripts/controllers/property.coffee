app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsPropertyCtrl', ($scope, $stateParams, $log, rmapsPropertiesService, rmapsFormattersService, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsGoogleService, rmapsMapFactory) ->
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

    rmapsPropertiesService.getPropertyDetail(null, {rm_property_id: propertyId }, 'all')
    .then (data) ->
      $scope.selectedResult = data

  getPropertyDetail $stateParams.id

  return
