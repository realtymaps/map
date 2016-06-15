commonConfig = require '../../../../../common/config/commonConfig.coffee'
app = require '../../app.coffee'

app.controller 'rmapsModalSendMailCtrl', ($scope, $state, $log, wizard, rmapsMailCampaignService) ->
  $scope.sendingFlag = false
  $scope.bodyMessage = 'There\'s no turning back!'
  $scope.statusMessage = ''
  $scope.failedFlag = false
  $scope.successFlag = false
  $scope.sentinel = false
  $scope.wizard = wizard
  $scope.wizard.mail.getReviewDetails()
  .then (review) ->
    $scope.review = review
  $scope.send = () ->
    if $scope.sentinel
      $scope.sendingFlag = true
      rmapsMailCampaignService.send(mail.campaign.id).success (response) ->
        $scope.bodyMessage = "Mail campaign \"#{mail.campaign.name}\" submitted!"
        $scope.statusMessage = ''
        $scope.sendingFlag = false
        $scope.successFlag = true
      .error (data, status) ->
        $scope.failedFlag = true
        if data?.errmsg
          $scope.bodyMessage = data.errmsg.text
          if data.errmsg.troubleshooting
            $scope.bodyMessage += "\n#{data.errmsg.troubleshooting}"
        else
          $scope.bodyMessage = commonConfig.UNEXPECTED_MESSAGE()
        $scope.sendingFlag = false
    else
      $scope.statusMessage = 'Checkbox must be checked in order to submit!'

  $scope.cancel = () ->
    $scope.$close($scope.successFlag)

