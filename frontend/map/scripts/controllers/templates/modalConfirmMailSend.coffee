commonConfig = require '../../../../../common/config/commonConfig.coffee'
app = require '../../app.coffee'

app.controller 'rmapsModalSendMailCtrl', ($scope, $state, price, rmapsMailTemplateService, rmapsLobService, rmapsEventConstants) ->
  $scope.price = price
  $scope.sendingFlag = false
  $scope.message = 'There\'s no turning back!'
  $scope.failedFlag = false
  $scope.send = () ->
    $scope.sendingFlag = true
    rmapsLobService.submit rmapsMailTemplateService.getLobData()
    .success (response) ->
      rmapsMailTemplateService.setStatus 'sent'
      rmapsMailTemplateService.save(silent: true)
      .then () ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: "Mail campaign \"#{mailCampaign.name}\" submitted!", type: 'rm-success' }
        $scope.$close('sent')

    .error (data, status) ->
      $scope.failedFlag = true
      if data?.errmsg
        $scope.message = data.errmsg.text
      else
        $scope.message = commonConfig.UNEXPECTED_MESSAGE()

  $scope.cancel = () ->
    $scope.$dismiss()

