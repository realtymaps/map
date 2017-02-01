app = require '../../app.coffee'


app.controller 'rmapsStatsSignupsCtrl', ($scope, $log, rmapsStatsService) ->
  $scope.chart =
    domain: [new Date(2015, 8, 1), new Date()]
    doZoom: true
    format: "%Y-%m-%d"
    fields:
      value: 'count'

  rmapsStatsService.signUps(cache:false).then (data) ->
    $scope.chart.data = data
