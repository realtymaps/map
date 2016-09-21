app = require '../app.coffee'
module.exports = app
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsMailModalCtrl', ($scope, $state, $uibModal, $log, rmapsPropertiesService, rmapsMailCampaignService) ->
  $log = $log.spawn 'mail:rmapsMailModalCtrl'
  $log.debug 'MailModalCtrl'

  $scope.getMail = (property) ->
    rmapsMailCampaignService.getMail(property?.rm_property_id)

  $scope.addMail = () ->
    property_ids = _.keys rmapsPropertiesService.pins
    $scope.modalTitle = "Create Mail Campaign"

    if property_ids.length
      $scope.modalBody = "Create a mailing for #{property_ids.length} pinned properties?"
      $scope.modalOk = () ->
        modalInstance.dismiss()
        $state.go 'recipientInfo', {property_ids}, {reload: true}
    else
      $scope.modalBody = "Pin some properties first"
      $scope.showCancelButton = false

    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()

  rmapsMailCampaignService.getProjectMail()

app.controller 'rmapsMapMailCtrl', ($scope, $log, rmapsLayerFormattersService, rmapsMailCampaignService) ->
  $log = $log.spawn 'mail:rmapsMapMailCtrl'
  $log.debug 'MapMailCtrl'

  getMail = () ->
    rmapsMailCampaignService.getProjectMail()
    .then (mail) ->
      $log.debug "received mail data #{mail.length} " if mail?.length
      $scope.mailings = mail
      $scope.map.markers.mail = rmapsLayerFormattersService.setDataOptions mail, rmapsLayerFormattersService.MLS.setMarkerMailOptions

  $scope.map.getMail = getMail

  getMail()
