app = require '../app.coffee'

app.controller 'rmapsUtilsCtrl', ($scope) ->

app.controller 'rmapsUtilsFipsCodesCtrl', ($scope, rmapsFipsCodesService) ->

  $scope.$watch 'location.usStateCode', (usStateCode) ->
    return unless usStateCode

    rmapsFipsCodesService.getAllByState usStateCode
    .then (counties) ->
      $scope.counties = counties

app.controller 'rmapsUtilsMailCtrl', ($scope, $http, $log) ->
  $log = $log.spawn 'rmapsUtilsMailCtrl'
  $log.debug 'rmapsUtilsMailCtrl'
  $scope.letters = []
  $http.get '/mailLetters', cache: false
  .then ({data}) ->
    $scope.letters = data

  $scope.sendLetter = (letter) ->
    $http.post "/testLetter/#{letter.id}", {}
    .then ({data}) ->
      $log.debug data
