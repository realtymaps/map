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
      $scope.tab.selected = $scope.dataSources[0].data_source_id

      PHOTO_WIDTH = 275
      for property in $scope.dataSources
        photos = []
        if property.cdn_photo && property.photo_count
          for i in [1..property.photo_count]
            photos.push
              key: i
              # url: "http://" + property.cdn_photo + "&width=#{PHOTO_WIDTH}&image_id=#{i}"
              # Uncomment this to load photos locally
              url: property.cdn_photo.replace(property.cdn_photo.split('/')[0], '') + "&width=#{PHOTO_WIDTH}&image_id=#{i}"

        property.photos = photos
        $log.debug property.photos

  getPropertyDetail $stateParams.id

  $scope.$on 'imageLoaded', (event, img) ->
    $scope.imageLoaded = true
    $scope.$evalAsync()

  return
