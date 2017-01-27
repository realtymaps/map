app = require '../../app.coffee'
previewModalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsReviewCtrl', (
  $rootScope,
  $scope,
  $log,
  $state,
  $uibModal,
  $q,
  rmapsMailCampaignService,
  rmapsMailTemplateTypeService,
  rmapsMainOptions,
  rmapsMapTogglesFactory
  rmapsCreditCardFactory
) ->
  $log = $log.spawn 'mail:review'
  $log.debug 'rmapsReviewCtrl'

  creditCardFact = rmapsCreditCardFactory($scope)

  $scope.statusNames = rmapsMainOptions.mail.statusNames

  $scope.sendMail = () ->
    cardsPromise = $q.resolve()
    if !creditCardFact.hasCards()
      cardsPromise = creditCardFact.addCC()

    cardsPromise.then (result) ->
      $uibModal.open(
        template: require('../../../html/views/templates/modal-confirmMailSend.tpl.jade')()
        controller: 'rmapsModalSendMailCtrl'
        keyboard: false
        backdrop: 'static'
        windowClass: 'confirm-mail-modal'
        resolve:
          wizard: -> $scope.wizard
      )
      .result.then (result) ->
        $log.debug "modal result: #{result}"
        if result
          $state.go('review', { id: $scope.wizard.mail.campaign.id }, { reload: true })

  $scope.showAddresses = (addresses) ->
    $scope.addressList = addresses

    $uibModal.open
      template: require('../../../html/views/templates/modals/addressList.jade')()
      windowClass: 'address-list-modal'
      scope: $scope

  $scope.reviewPreview = () ->
    $uibModal.open
      template: previewModalTemplate
      controller: 'rmapsReviewPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          pdf: $scope.wizard.mail.review.pdf
          title: 'Mail Review'

  $scope.viewMap = () ->
    rmapsMapTogglesFactory.currentToggles?.showMail = true
    $state.go 'map'

  $scope.refreshColorPrice = () ->
    $scope.review = null
    $scope.wizard.mail.refreshColorPrice()
    .then (review) ->
      $scope.review = review

  $scope.wizard.mail.getReviewDetails()
  .then (review) ->
    $scope.review = review
