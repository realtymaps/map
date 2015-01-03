app = require '../app.coffee'

module.exports =
  app.controller 'MockResultsTrayCtrl'.ourNs(), [
    '$scope', 'ResultsFormatter'.ourNs(), '$http',
    ($scope, ResultsFormatter, $http) ->
      angular.extend $scope,
        layers:
          filterSummary: []
        Toggles:
          showResults: true

      $http.get('mocks/filter_summary.json')
      .then (data) ->
        $scope.layers.filterSummary = data.data

      $scope.resultsFormatter = new ResultsFormatter($scope)
      $scope.resultsFormatter.loadMore()
  ]