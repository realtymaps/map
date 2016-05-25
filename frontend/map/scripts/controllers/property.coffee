app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsPropertyCtrl', ($scope, $stateParams, $log, $modal, rmapsPropertiesService, rmapsFormattersService,
rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsGoogleService, rmapsMailCampaignService) ->
  $log = $log.spawn 'rmapsPropertyCtrl'
  $log.debug "rmapsPropertyCtrl for id: #{$stateParams.id}"

  _.extend $scope, rmapsFormattersService.Common,

  $scope.google = rmapsGoogleService

  $scope.getMail = () ->
    rmapsMailCampaignService.getMail $stateParams.id

  $scope.tab = selected: ''

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  _.merge @scope,
    streetViewPanorama:
      status: 'OK'
    control: {}

  $scope.previewLetter = (mail) ->
    $modal.open
      template: require('../../html/views/templates/modal-mailPreview.tpl.jade')()
      controller: 'rmapsReviewPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          pdf: mail.lob.url
          title: 'Mail Review'

  $scope.showDCMA = (mls) ->
    $modal.open
      template: require('../../html/views/templates/modal-dmca.tpl.jade')()
      controller: 'rmapsModalInstanceCtrl'
      resolve: model: -> mls

  getPropertyDetail = (propertyId) ->
    $log.debug "Getting property detail for #{propertyId}"

    rmapsPropertiesService.getPropertyDetail(null, {rm_property_id: propertyId }, 'all', false)
    .then (property) ->
      $scope.selectedResult = property
      $scope.dataSources = [].concat(property.county||[]).concat(property.mls||[])
      $scope.tab.selected = (property.mls[0] || property.county[0])?.data_source_id || 'raw'
      for dataSource in $scope.dataSources
        $log.debug dataSource
        for groupName, group of dataSource.shared_groups
          dataSource.shared_groups[groupName] = _.zipObject _.map(group, 'name'), _.map(group, 'value')
          $log.debug group

  getPropertyDetail $stateParams.id
