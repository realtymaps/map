app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsReviewCtrl', ($rootScope, $scope, $log, $q, $state, $modal, rmapsLobService, rmapsMailCampaignService) ->
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
        price: $scope.priceQuote
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

  $scope.sentFlag = false
  $scope.category = null
  $scope.priceQuote = null
  $scope.details =
    pdf: null

  $scope.statusNames =
    'ready': 'draft'
    'sending': 'pending'
    'paid': 'sent'

  getQuote = () ->
    if $scope.wizard.mail.isSent()
      return $q.when("Mailing submitted. Lob Batch Id: #{$scope.wizard.mail.campaign.lob_batch_id}")
    if $scope.wizard.mail.campaign?.recipients?.length == 0
      return $q.when("0.00")
    rmapsLobService.getQuote $scope.wizard.mail.campaign.id
    .then (quote) ->
      $log.debug -> "getquote data: #{JSON.stringify(quote)}"
      quote

  getReviewDetails = () ->
    rmapsMailCampaignService.getReviewDetails($scope.wizard.mail.campaign.id)

  $rootScope.registerScopeData () ->
    $scope.ready()
    .then () ->
      $scope.category = $scope.wizard.mail.getCategory()
      $scope.sentFlag = $scope.wizard.mail.isSent()
      getQuote()
      .then (response) ->
        $scope.priceQuote = response
        if $scope.sentFlag
          getReviewDetails()
          .then (details) ->
            $scope.details.pdf = details.pdf

