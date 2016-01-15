app = require '../app.coffee'
module.exports = app

app.controller 'rmapsMapMailCtrl', ($scope, $state, $modal, rmapsprincipal, rmapsMailTemplate) ->

  $scope.addMail = () ->
    profile = rmapsprincipal.getCurrentProfile()
    return if not profile

    property_ids = _.keys profile.properties_selected

    $scope.newMail =
      property_ids: property_ids

    $scope.modalTitle = "Create Mail Campaign"

    if property_ids.length
      $scope.modalBody = "Do you want to create a campaign for the #{property_ids.length} selected properties?"

      $scope.modalOk = () ->
        modalInstance.dismiss('save')
        rmapsMailTemplate.create $scope.newMail
        $state.go 'recipientInfo'

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
