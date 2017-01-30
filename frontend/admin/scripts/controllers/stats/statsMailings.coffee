app = require '../../app.coffee'


app.controller 'rmapsStatsMailingsCtrl', ($scope, $log, rmapsStatsService) ->
  $scope.chart =
    domain: [new Date(2015, 8, 1), new Date()]
    doZoom: true
    format: "%Y-%m-%d"
    fields:
      value: 'count'

  rmapsStatsService.mailings(cache:false).then (data) ->
    $scope.chart.data = data
