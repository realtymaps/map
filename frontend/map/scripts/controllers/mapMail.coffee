app = require '../app.coffee'
module.exports = app

app.controller 'rmapsMapMailCtrl', ($scope, $state, $modal, $log, rmapsPropertiesService) ->
  $log = $log.spawn 'mail:rmapsMapMailCtrl'

  $scope.addMail = (maybeParcel) ->

    savedProperties = rmapsPropertiesService.getSavedProperties()

    if maybeParcel?
      property_ids = [maybeParcel.rm_property_id]
    else
      property_ids = _.keys savedProperties

    $scope.newMail =
      property_ids: property_ids

    $scope.modalTitle = "Create Mail Campaign"

    if $scope.newMail.property_ids.length
      $scope.modalBody = "Do you want to create a campaign for the #{$scope.newMail.property_ids.length} selected properties?"

      $scope.modalOk = () ->
        modalInstance.dismiss('save')
        $log.debug "$state.go 'recipientInfo'..."
        $state.go 'recipientInfo', {property_ids: $scope.newMail.property_ids}, {reload: true}

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
