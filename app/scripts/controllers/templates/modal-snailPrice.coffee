app = require '../../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

app.controller 'ModalSnailPriceCtrl'.ourNs(), ['$scope', '$http', '$interpolate', '$location', ($scope, $http, $interpolate, $location) ->
  
  $scope.$interpolate = $interpolate
  $scope.statuses =
    error: 0
    fetching: 1
    asking: 2
    sending: 3
    sent: 4
  $scope.messages = [
    {status: $scope.statuses.fetching,  text: 'Checking price...'}
    {status: $scope.statuses.asking,    text: 'It will cost you ${{price}} to send this via snail mail.  Do you want to do it?'}
    {status: $scope.statuses.sending,   text: 'Queuing mailing...'}
    {status: $scope.statuses.sent,      text: 'Done! Your mailing should be processed, printed, and placed in the mail within the next 2-3 business days.'}
  ]
  $scope.messageData = {}
  $scope.lteCurrentStatus = (message) ->
    return message.status <= $scope.modalControl.status
    
  handleHttp = (httpPromise, handler) ->
    httpPromise
    .success (data, status) ->
      if data?.errmsg
        $scope.messages.push(status: $scope.statuses.error, text: data.errmsg.text, troubleshooting: data.errmsg.troubleshooting)
        return
      if !httpStatus.isWithinOK status
        return
      handler(data)
    .error (data, status) ->
      if data?.errmsg
        $scope.messages.push(status: $scope.statuses.error, text: data.errmsg.text, troubleshooting: data.errmsg.troubleshooting)
  
  $scope.modalControl.status = $scope.statuses.fetching
  handleHttp $http.post(backendRoutes.snail.quote, _.extend(rm_property_id: $scope.data.property.rm_property_id, $scope.form)), (data) ->
    $scope.messageData.price = data.price
    $scope.modalControl.status = $scope.statuses.asking

  $scope.send = () ->
    $scope.modalControl.status = $scope.statuses.sending
    handleHttp $http.post(backendRoutes.snail.send, _.extend(rm_property_id: $scope.data.property.rm_property_id, $scope.form)), (data) ->
      $scope.modalControl.status = $scope.statuses.sent

  $scope.done = () ->
    $location.url(frontendRoutes.map)
    $scope.$close('done')
]
