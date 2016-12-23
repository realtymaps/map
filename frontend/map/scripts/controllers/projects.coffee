app = require '../app.coffee'

module.exports = app

app.controller 'rmapsProjectsCtrl', (
  $rootScope,
  $scope,
  $http,
  $state,
  $log,
  $uibModal,
  rmapsProfilesService,
  rmapsProjectsService,
  rmapsEventConstants
) ->
  $scope.activeView = 'projects'
  $log = $log.spawn("map:projects")
  $log.debug 'projectsCtrl'

  $scope.projects = []
  $scope.newProject = {}

  $scope.archiveProject = (project) ->
    rmapsProjectsService.archive project

  $scope.addProject = () ->
    $scope.newProject = {}

    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/addProjects.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')

      rmapsProjectsService.createProject $scope.newProject
      .then (currentProfile) ->
        $scope.loadProjects()
        rmapsProfilesService.setCurrentProfileByProfileId(currentProfile.id)

  $scope.loadMap = (project) ->
    $state.go 'map', project_id: project.id, {reload: true}

  $scope.deleteProject = (project) ->
    if project.sandbox
      $scope.modalTitle = "Do you really want to clear your Sandbox?"
    else
      $log.debug project
      $scope.modalTitle = "Do you really want to delete \"#{project.name}\"?"

    $scope.modalBody = "All notes, drawings, pins and favorites will be discarded"

    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()

    $scope.modalCancel = () ->
      modalInstance.dismiss('cancel')

    $scope.modalOk = () ->
      modalInstance.dismiss('ok')

      rmapsProjectsService.deleteProject project.id
      .then (currentProfile) ->
        $scope.loadProjects()
        rmapsProfilesService.setCurrentProfileByProfileId(currentProfile.id)

  $scope.loadProjects = () ->
    rmapsProjectsService.getProjects()
    .then (projects) ->
      $scope.projects = projects
    .catch (error) ->
      $log.error error

  $scope.loadProjects()

  # When a project is added or removed elsewhere, this event will fire
  $rootScope.$onRootScope rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    $scope.loadProjects()
