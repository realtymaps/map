app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
moment = require 'moment'
_ = require 'lodash'

app.controller 'rmapsErrorsCtrl', () ->

app.controller 'rmapsErrorsBrowserCtrl', ($scope, $http, $log, $location) ->
  $log = $log.spawn 'rmapsErrorsBrowserCtrl'

  $scope.opts =
    limit: 50
    distinct: true
    unhandled: true
    sourcemap: 's3'

  loadErrors = ->
    $http.get(backendRoutes.errors.browser, params: _.omit($scope.opts, 'sourcemap'))
    .then ({data}) ->
      $scope.errors = []
      for error in data
        $scope.errors.push(error, {parent: error})

  $scope.$watchCollection 'opts', ->
    loadErrors()

  $scope.getFilePath = (path) ->
    path?.replace("../src/", "")

  $scope.expand = (error) ->
    if !error.parent
      error.expanded = !error.expanded
      if !error.betterStack?
        $http.get(backendRoutes.errors.browser, params: {reference: error.reference, sourcemap: $scope.opts.sourcemap})
        .then ({data}) ->
          if data?[0]?.betterStack
            error.betterStack = data?[0]?.betterStack
          else
            error.betterStack = false

  $scope.getTime = (error) ->
    moment(error.rm_inserted_time).fromNow()

  $scope.handle = (error) ->
    handled = !error.handled
    $http.post(backendRoutes.errors.browser + "/#{error.reference}", {handled})
    .then () ->
      error.handled = handled

app.controller 'rmapsErrorsAPICtrl', ($scope, $http, $log, $location) ->
  $log = $log.spawn 'rmapsErrormapsErrorsAPICtrlrsBrowserCtrl'

  $scope.opts =
    limit: 50
    distinct: true
    unhandled: true
    unexpected: true
    '404': false

  loadErrors = ->
    $http.get(backendRoutes.errors.request, params: $scope.opts)
    .then ({data}) ->
      $scope.errors = []
      for error in data
        $scope.errors.push(error, {parent: error})

  $scope.$watchCollection 'opts', ->
    loadErrors()

  $scope.expand = (error) ->
    if !error.parent
      error.expanded = !error.expanded

  $scope.getTime = (error) ->
    moment(error.rm_inserted_time).fromNow()

  $scope.handle = (error) ->
    handled = !error.handled
    $http.post(backendRoutes.errors.request + "/#{error.reference}", {handled})
    .then () ->
      error.handled = handled
