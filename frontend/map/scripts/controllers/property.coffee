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

  $scope.groups = [
    name: 'general', label: 'General Info', subscriber: 'shared_groups'
   ,
    name: 'details', label: 'Details', subscriber: 'shared_groups'
   ,
    name: 'listing', label: 'Listing', subscriber: 'shared_groups'
   ,
    name: 'building', label: 'Building', subscriber: 'shared_groups'
   ,
    name: 'dimensions', label: 'Room Dimensions', subscriber: 'shared_groups'
   ,
    name: 'lot', label: 'Lot', subscriber: 'shared_groups'
   ,
    name: 'location', label: 'Location & Schools', subscriber: 'shared_groups'
   ,
    name: 'restrictions', label: 'Taxes, Fees and Restrictions', subscriber: 'shared_groups'
   ,
    name: 'contacts', label: 'Listing Contacts', subscriber: 'subscriber_groups'
   ,
    name: 'realtor', label: 'Listing Details', subscriber: 'subscriber_groups'
   ,
    name: 'sale', label: 'Sale Details', subscriber: 'subscriber_groups',
  ,
    name: 'owner', label: 'Owner', subscriber: 'subscriber_groups'
   ,
    name: 'deed', label: 'Deed', subscriber: 'subscriber_groups'
   ,
    name: 'mortgage', label: 'Mortgage', subscriber: 'subscriber_groups'
  ]

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

  getPropertyDetail $stateParams.id
