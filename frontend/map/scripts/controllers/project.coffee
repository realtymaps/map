app = require '../app.coffee'

module.exports = app

app.controller 'rmapsProjectCtrl', ($rootScope, $scope, $http, $log, $state, rmapsprincipal, rmapsProjects) ->
  $scope.activeView = 'project'
  $log = $log.spawn("map:project")
  $log.debug 'projectCtrl'

  $scope.selected = 'project'
  $scope.project = null

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjects.archive project

  $scope.loadProject = (id) ->
    rmapsProjects.getProject id
    .then (project) ->
      console.log project
      $scope.project = project
    .catch (error) ->
      $log.error error

  $rootScope.registerScopeData () ->
    if $state.params.id
      $scope.loadProject($state.params.id)
