app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsReviewCtrl', ($rootScope, $scope, $log, $q, $state, $modal, rmapsLobService, rmapsMailCampaignService, rmapsMainOptions) ->
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

  $scope.priceQuote = null
  $scope.review = null
  $scope.statusNames = rmapsMainOptions.mail.statusNames

  if !$scope.wizard.mail.isSubmitted()
    rmapsLobService.getQuote($scope.wizard.mail.campaign.id)
    .then (quote) ->
      $scope.priceQuote = quote
  else
    rmapsMailCampaignService.getReviewDetails($scope.wizard.mail.campaign.id)
    .then (review) ->
      $scope.review = review
