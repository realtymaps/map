app = require '../app.coffee'
module.exports = app

app.controller 'rmapsMapMailCtrl', ($scope, $state, $modal, $log, rmapsPrincipalService, rmapsPropertiesService, rmapsMailTemplateService) ->
  $log = $log.spawn 'mail:rmapsMapMailCtrl'

  $scope.addMail = (maybeParcel) ->
    #profile = rmapsPrincipalService.getCurrentProfile()
    savedProperties = rmapsPropertiesService.getSavedProperties()

    if maybeParcel?
      property_ids = [maybeParcel.rm_property_id]
    else
      property_ids = _.keys savedProperties

    $scope.newMail =
      property_ids: property_ids

    $scope.modalTitle = "Create Mail Campaign"

    if property_ids.length
      $scope.modalBody = "Do you want to create a campaign for the #{property_ids.length} selected properties?"

      $scope.modalOk = () ->
        modalInstance.dismiss('save')
        rmapsMailTemplateService.create $scope.newMail
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
