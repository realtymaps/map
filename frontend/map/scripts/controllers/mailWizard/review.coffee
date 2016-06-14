app = require '../../app.coffee'
_ = require 'lodash'
previewModalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsReviewCtrl', ($rootScope, $scope, $log, $state, $modal,
rmapsMailCampaignService, rmapsMailTemplateTypeService, rmapsMainOptions, rmapsMapTogglesFactory) ->
  $log = $log.spawn 'mail:review'
  $log.debug 'rmapsReviewCtrl'

  $scope.statusNames = rmapsMainOptions.mail.statusNames

  $scope.sendMail = () ->
    modalInstance = $modal.open
      template: require('../../../html/views/templates/modal-confirmMailSend.tpl.jade')()
      controller: 'rmapsModalSendMailCtrl'
      keyboard: false
      backdrop: 'static'
      # windowClass: 'confirm-mail-modal'
      scope: $scope
      resolve:
        mail: -> $scope.wizard.mail

    modalInstance.result.then (result) ->
      $log.debug "modal result: #{result}"
      if result
        $state.go('review', { id: $scope.wizard.mail.campaign.id }, { reload: true })

  $scope.showAddresses = (addresses) ->
    $scope.addressList = addresses
    modalInstance = $modal.open
      template: require('../../../html/views/templates/modals/addressList.jade')()
      windowClass: 'address-list-modal'
      scope: $scope

  $scope.reviewPreview = () ->
    modalInstance = $modal.open
      template: previewModalTemplate
      controller: 'rmapsReviewPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      scope: $scope
      resolve:
        template: -> $scope.wizard.mail.review

  $scope.viewMap = () ->
    rmapsMapTogglesFactory.currentToggles?.showMail = true
    $state.go 'map'

  $scope.wizard.mail.getReviewDetails()
  .then (review) ->
    $scope.review = review
