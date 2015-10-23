app = require '../app.coffee'

module.exports = app

app.controller 'rmapsProjectsCtrl', ($rootScope, $scope, $http, $log, $modal, rmapsprincipal, rmapsProjectsService) ->
  $scope.activeView = 'projects'
  $log = $log.spawn("map:projects")
  $log.debug 'projectsCtrl'

  $scope.projects = []
  $scope.newProject = {}

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjectsService.archive project

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
      rmapsProjectsService.createProject $scope.newProject
      .then (response) ->
        $scope.loadProjects()

  $scope.loadProjects = () ->
    rmapsProjectsService.getProjects()
    .then (projects) ->
      $scope.projects = projects
      for project in projects
        project.propertiesTotal = _.keys(project.properties_selected).length
    .catch (error) ->
      $log.error error

  $rootScope.registerScopeData () ->
    $scope.loadProjects()
