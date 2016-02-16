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
#    rmapsPropertiesService.getProperties propertyId, 'detail'
#    .then (result) ->
#      $log.debug "Have results for property detail for id #{propertyId}"
#      $scope.selectedResult = result.data[0]

    rmapsPropertiesService.getPropertyDetail(rmapsMapFactory.mapCtrl.scope.refreshState(
      map_results:
        selectedResultId: propertyId)
    , {rm_property_id: propertyId }, 'all')
    .then (data) ->
      $scope.selectedResult = data

  getPropertyDetail $stateParams.id

  return
