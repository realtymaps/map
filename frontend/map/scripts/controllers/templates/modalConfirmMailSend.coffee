commonConfig = require '../../../../../common/config/commonConfig.coffee'
app = require '../../app.coffee'

app.controller 'rmapsModalSendMailCtrl', (
  $scope,
  $state,
  $log,
  wizard,
  rmapsMailCampaignService
) ->
  $scope.sendingFlag = false
  $scope.bodyMessage = 'Your mail will be printed and arrive in 4-5 days.'
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
      rmapsMailCampaignService.send($scope.wizard.mail.campaign.id).then () ->
        $scope.bodyMessage = "Mail campaign \"#{$scope.wizard.mail.campaign.name}\" submitted!"
        $scope.statusMessage = ''
        $scope.sendingFlag = false
        $scope.successFlag = true
      .catch ({data, status}) ->
        $scope.failedFlag = true
        if data?.errmsg
          $scope.bodyMessage = data.errmsg.text
          if data.errmsg.troubleshooting
            $scope.bodyMessage += "\n#{data.errmsg.troubleshooting}"
        else if data?.alert?.msg
          errorMessage = data?.alert?.msg
          errorReference = errorMessage.match(/\(Error reference.*\)/)?[0]
          if errorReference
            errorMessage = data.alert.msg.replace(errorReference, '')
            $scope.errorReference = errorReference
          $scope.bodyMessage = errorMessage
        else # generic message
          $scope.bodyMessage = commonConfig.UNEXPECTED_MESSAGE()
        $scope.sendingFlag = false
    else
      $scope.statusMessage = 'Checkbox must be checked in order to submit!'

  $scope.cancel = () ->
    $scope.$close($scope.successFlag)
