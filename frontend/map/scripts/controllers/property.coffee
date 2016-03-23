app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsPropertyCtrl', ($scope, $stateParams, $log, $modal, rmapsPropertiesService, rmapsFormattersService, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsGoogleService, rmapsMailCampaignService) ->
  $log = $log.spawn 'rmapsPropertyCtrl'
  $log.debug "rmapsPropertyCtrl for id: #{$stateParams.id}"

  _.extend $scope,
    rmapsFormattersService.Common,
    google: rmapsGoogleService
    getMail: () ->
      rmapsMailCampaignService.getMail $stateParams.id

  $scope.tab = 'current'

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  _.merge @scope,
    streetViewPanorama:
      status: 'OK'
    control: {}

  $scope.previewLetter = (mail) ->
    $log.debug mail
    $scope.mail = mail
    modalInstance = $modal.open
      template: require('../../html/views/templates/modals/letterPreview.jade')()
      windowClass: 'letter-preview-modal'
      scope: $scope

    $scope.close = modalInstance.dismiss

  getPropertyDetail = (propertyId) ->
    $log.debug "Getting property detail for #{propertyId}"

    rmapsPropertiesService.getPropertyDetail(null, {rm_property_id: propertyId }, 'all', false)
    .then (property) ->
      $scope.selectedResult = property

  getPropertyDetail $stateParams.id

  return
