commonConfig = require '../../../../../common/config/commonConfig.coffee'
app = require '../../app.coffee'

app.controller 'rmapsModalSendMailCtrl', ($scope, $state, price, rmapsMailTemplateService, rmapsLobService, rmapsEventConstants) ->
  $scope.price = price
  $scope.sendingFlag = false
  $scope.bodyMessage = 'There\'s no turning back!'
  $scope.statusMessage = ''
  $scope.failedFlag = false
  $scope.successFlag = false
  $scope.sentinel = false
  $scope.send = () ->
    if $scope.sentinel
      $scope.sendingFlag = true
      rmapsLobService.getQuote(rmapsMailTemplateService.getLobData()).then (response) ->
      #rmapsLobService.submit(rmapsMailTemplateService.getLobData()).success (response) ->
        rmapsMailTemplateService.setStatus 'sent'
        rmapsMailTemplateService.save()
        .then () ->
          #$rootScope.$emit rmapsEventConstants.alert.spawn, { msg: "Mail campaign \"#{mailCampaign.name}\" submitted!", type: 'rm-success' }
          $scope.bodyMessage = "Mail campaign \"#{rmapsMailTemplateService.getCampaign().name}\" submitted!"
          $scope.statusMessage = ''
          $scope.sendingFlag = false
          $scope.successFlag = true
      .error (data, status) ->
        $scope.failedFlag = true
        if data?.errmsg
          $scope.bodyMessage = data.errmsg.text
        else
          $scope.bodyMessage = commonConfig.UNEXPECTED_MESSAGE()
        $scope.sendingFlag = false
    else
      $scope.statusMessage = 'Checkbox must be checked in order to submit!'

  $scope.cancel = () ->
    $scope.$close($scope.successFlag)

