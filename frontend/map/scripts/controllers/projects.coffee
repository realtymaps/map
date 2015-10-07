app = require '../app.coffee'

module.exports = app

app.controller 'rmapsProjectsCtrl', ($rootScope, $scope, $http, $log, $modal, rmapsprincipal, rmapsProjects) ->
  $scope.activeView = 'projects'
  $log = $log.spawn("map:projects")
  $log.debug 'projectsCtrl'

  $scope.projects = []
  $scope.newProject = {}

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjects.archive project

  $scope.addProject = () ->
    $scope.newProject = {}

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/addProjects.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')
      rmapsProjects.createProject $scope.newProject
      .then (response) ->
        $scope.loadProjects()

  $scope.loadProjects = () ->
    rmapsProjects.getProjects()
    .then (projects) ->
      $scope.projects = projects
    .catch (error) ->
      $log.error error

  $rootScope.registerScopeData () ->
    $scope.loadProjects()
