app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsReviewCtrl', ($rootScope, $scope, $log, $q, $timeout, $state, $modal, rmapsMailTemplateService, rmapsLobService, rmapsMailCampaignService) ->
  $log = $log.spawn 'mail:review'
  $log.debug 'rmapsReviewCtrl'

  # $scope.templObj =
  #   mailCampaign: {}

  # setTemplObj = () ->
  #   $scope.templObj =
  #     mailCampaign: rmapsMailTemplateService.getCampaign()

  # $scope.quoteAndSend = () ->
  #   $scope.$parent.quoteAndSend()

  # $scope.sendMail = () ->
  #   $scope.$parent.sendMail()

  $scope.sendMail = () ->
    modalInstance = $modal.open
      template: require('../../../html/views/templates/modal-confirmMailSend.tpl.jade')()
      controller: 'rmapsModalSendMailCtrl'
      keyboard: false
      backdrop: 'static'
      windowClass: 'confirm-mail-modal'
      resolve:
        price: $scope.priceQuote

    modalInstance.result.then (result) ->
      $log.debug "modal result: #{result}"
      if result
        $state.go('review', { id: $scope.wizard.mail.campaign.id }, { reload: true })

  $scope.showAddresses = (addresses) ->
    $log.debug addresses
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

  getQuote = () ->
    if rmapsMailTemplateService.isSent()
      return $q.when("Mailing submitted. Lob Batch Id: #{$scope.wizard.mail.campaign.lob_batch_id}")
    if $scope.wizard.mail.campaign?.recipients?.length == 0
      return $q.when("0.00")
    rmapsLobService.getQuote rmapsMailTemplateService.getLobData()
    .then (quote) ->
      $log.debug -> "getquote data: #{JSON.stringify(quote)}"
      quote

  getReviewDetails = () ->
    rmapsMailCampaignService.getReviewDetails($scope.wizard.mail.campaign.id)

  $rootScope.registerScopeData () ->
    $scope.ready()
    .then () ->
      # setTemplObj()
      $scope.category = rmapsMailTemplateService.getCategory()
      $scope.sentFlag = rmapsMailTemplateService.isSent()
      getQuote()
      .then (response) ->
        $scope.priceQuote = response
        if $scope.sentFlag
          getReviewDetails()
          .then (details) ->
            $scope.details.pdf = details.pdf

