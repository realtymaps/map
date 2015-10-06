app = require '../app.coffee'

module.exports = app

app.controller 'rmapsProjectsCtrl', ($rootScope, $scope, $http, $log, rmapsprincipal, rmapsProjects) ->
  $scope.activeView = 'projects'
  $log = $log.spawn("map:projects")
  $log.debug 'projectsCtrl'

  $scope.projects = []
  $scope.selected = {}

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjects.archive project

  $rootScope.registerScopeData () ->
    rmapsProjects.getProjects()
    .then (projects) ->
      $scope.projects = projects
    .catch (error) ->
      $log.error error
