app = require '../../app.coffee'
_ = require 'lodash'
previewModalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsReviewCtrl', ($rootScope, $scope, $log, $q, $state, $modal, rmapsLobService,
rmapsMailCampaignService, rmapsMailTemplateTypeService) ->
  $log = $log.spawn 'mail:review'
  $log.debug 'rmapsReviewCtrl'

  $scope.sendMail = () ->
    modalInstance = $modal.open
      template: require('../../../html/views/templates/modal-confirmMailSend.tpl.jade')()
      controller: 'rmapsModalSendMailCtrl'
      keyboard: false
      backdrop: 'static'
      windowClass: 'confirm-mail-modal'
      resolve:
        price: $scope.review.price
        mail: $scope.wizard.mail

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

  $scope.review = null

  $scope.statusNames =
    'ready': 'draft'
    'sending': 'pending'
    'paid': 'sent'

  $scope.reviewPreview = () ->
    modalInstance = $modal.open
      template: previewModalTemplate
      controller: 'rmapsReviewPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () -> $scope.review
          # content: rmapsMailTemplateTypeService.getMailContent(template.type)
          # category: template.category
          # title: template.name

  rmapsMailCampaignService.getReviewDetails($scope.wizard.mail.campaign.id)
  .then (review) ->
    $scope.review = _.merge review, rmapsMailTemplateTypeService.getMeta()[$scope.wizard.mail.campaign.template_type]

