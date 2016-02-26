app = require '../app.coffee'
module.exports = app

app.controller 'rmapsMapMailCtrl', ($scope, $state, $modal, $log, rmapsMailRecipientService) ->
  $log = $log.spawn 'mail:rmapsMapMailCtrl'

  $scope.addMail = (maybeParcel) ->
    rmapsMailRecipientService.updatePropertyIds(maybeParcel)
    $scope.newMail =
      property_ids: rmapsMailRecipientService.getPropertyIds()

    $scope.modalTitle = "Create Mail Campaign"

    if $scope.newMail.property_ids.length
      $scope.modalBody = "Do you want to create a campaign for the #{$scope.newMail.property_ids.length} selected properties?"

      $scope.modalOk = () ->
        modalInstance.dismiss('save')
        $log.debug "$state.go 'recipientInfo'..."
        $state.go 'recipientInfo', {}, {reload: true}

      $scope.cancelModal = () ->
        modalInstance.dismiss('cancel')

    else
      $scope.modalBody = "Pin some properties first"

      $scope.modalOk = () ->
        modalInstance.dismiss('cancel')

      $scope.showCancelButton = false

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()
