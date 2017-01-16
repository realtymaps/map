app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
moment = require 'moment'

app.controller 'rmapsErrorsCtrl', () ->

app.controller 'rmapsErrorsBrowserCtrl', ($scope, $http, $log, $location) ->
  $log = $log.spawn 'rmapsErrorsBrowserCtrl'

  $scope.opts =
    limit: 100
    distinct: true
    unhandled: true
    sourcemap: 's3'

  loadErrors = ->
    $http.get(backendRoutes.errors.browser, params: $scope.opts)
    .then ({data}) ->
      $scope.errors = []
      for error in data
        $scope.errors.push(error)
        for frame in (error.stack ? error.originalStack ? [])
          frame.parent = error
          $scope.errors.push(frame)

  $scope.$watchCollection 'opts', ->
    loadErrors()

  $scope.getFilePath = (path) ->
    path.replace("../src/", "")

  $scope.expand = (error) ->
    if !error.parent
      error.expanded = !error.expanded

  $scope.getTime = (error) ->
    moment(error.rm_inserted_time).fromNow()

  $scope.handle = (error) ->
    handled = !error.handled
    $http.post(backendRoutes.errors.browser + "/#{error.reference}", {handled})
    .then () ->
      error.handled = handled

app.controller 'rmapsErrorsAPICtrl', () ->

