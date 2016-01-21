app = require '../../app.coffee'
frontendRoutes = require '../../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../../common/config/routes.backend.coffee'
httpStatus = require '../../../../../common/utils/httpStatus.coffee'
commonConfig = require '../../../../../common/config/commonConfig.coffee'

app.controller 'rmapsModalSnailPriceCtrl', ($scope, $http, $interpolate, $location, $log) ->

  $scope.$interpolate = $interpolate
  $scope.statuses =
    error: 0
    fetching: 1
    asking: 2
    sending: 3
    sent: 4
  $scope.messages = [
    {status: $scope.statuses.fetching,  text: 'Checking price...'}
    {status: $scope.statuses.asking,    text: 'It will cost you {{price | currency}} to send this via snail mail.  Do you want to do it?'}
    {status: $scope.statuses.sending,   text: 'Queuing mailing...'}
    {status: $scope.statuses.sent,      text: 'Done! Your mailing should be processed, printed, and placed in the mail within the next 2-3 business days.'}
  ]
  $scope.messageData = {}
  $scope.lteCurrentStatus = (message) ->
    return message.status <= $scope.modalControl.status

  handlePost = (postParams...) ->
    $http.post(postParams...)
    .error (data, status) ->
      if data?.errmsg
        $scope.messages.push
          status: $scope.statuses.error
          text: data.errmsg.text
          troubleshooting: data.errmsg.troubleshooting
      else
        $scope.messages.push
          status: $scope.statuses.error
          text: commonConfig.UNEXPECTED_MESSAGE()
          troubleshooting: JSON.stringify(status:status||null, data:data||null)

  $scope.modalControl.status = $scope.statuses.fetching

  handlePost(backendRoutes.snail.quote, $scope.lobData, alerts:false)
  .success (data) ->
    $scope.messageData.price = data.price
    $scope.modalControl.status = $scope.statuses.asking

  $scope.send = () ->
    $scope.modalControl.status = $scope.statuses.sending
    handlePost(backendRoutes.snail.send, $scope.lobData, alerts:false)
    .success () ->
      $scope.modalControl.status = $scope.statuses.sent

  $scope.done = () ->
    $location.url(frontendRoutes.map)
    $scope.$close('done')
