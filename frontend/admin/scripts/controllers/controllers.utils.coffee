app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsUtilsCtrl', ($scope) ->

app.controller 'rmapsUtilsFipsCodesCtrl', ($scope, rmapsFipsCodesService, rmapsUsStates) ->

  $scope.us_states = rmapsUsStates.all

  $scope.$watch 'location.usStateCode', (usStateCode) ->
    return unless usStateCode

    rmapsFipsCodesService.getAllByState usStateCode
    .then (counties) ->
      $scope.counties = counties

app.controller 'rmapsUtilsMailCtrl', ($scope, $http, $log) ->
  $log = $log.spawn 'rmapsUtilsMailCtrl'
  $log.debug 'rmapsUtilsMailCtrl'
  $scope.letters = []
  $http.get backendRoutes.mail.getLetters, cache: false
  .then ({data}) ->
    $scope.letters = data

  $scope.sendLetter = (letter) ->
    $http.post backendRoutes.mail.testLetter.replace(':letter_id', letter.id), {}
    .then ({data}) ->
      $log.debug data
      letter.status = 'sent'
