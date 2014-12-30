app = require '../app.coffee'
json = require '../../json/mocks/filter_summary.json'
module.exports =
  app.controller 'MockResultsTrayCtrl'.ourNs(), [
    '$scope', 'ResultsFormatter'.ourNs(),
    ($scope, ResultsFormatter) ->
      $scope.layers =
        filterSummary: JSON.parse(json)
      $scope.resultsFormatter = new ResultsFormatter($scope)
  ]