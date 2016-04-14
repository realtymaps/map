app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSmallDetailsCtrl', ($scope, $log, $modal, rmapsPropertiesService, rmapsFormattersService, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsGoogleService, rmapsMailCampaignService) ->
  $log = $log.spawn 'rmapsSmallDetailsCtrl'
  $log.debug "rm_property_id: #{JSON.stringify $scope.model.rm_property_id}"

  _.extend $scope,
    rmapsFormattersService.Common,
    google: rmapsGoogleService
    getMail: () ->
      rmapsMailCampaignService.getMail $scope.model.rm_property_id

  $scope.tab = 'current'

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  _.merge @scope,
    streetViewPanorama:
      status: 'OK'
    control: {}

  $scope.previewLetter = (mail) ->
    $modal.open
      template: require('../../../html/views/templates/modal-mailPreview.tpl.jade')()
      controller: 'rmapsReviewPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          pdf: mail.lob.url
          title: 'Mail Review'

  getPropertyDetail = (propertyId) ->
    $log.debug "Getting property detail for #{propertyId}"

    rmapsPropertiesService.getPropertyDetail(null, {rm_property_id: propertyId }, 'all', false)
    .then (property) ->
      $scope.selectedResult = property

  getPropertyDetail $scope.model.rm_property_id

  return
