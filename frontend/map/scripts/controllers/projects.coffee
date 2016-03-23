app = require '../app.coffee'

module.exports = app

app.controller 'rmapsProjectsCtrl', (
  $rootScope,
  $scope,
  $http,
  $state,
  $log,
  $modal,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsProjectsService,
  rmapsEventConstants
) ->
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
      currentProfileId = null

      rmapsProjectsService.createProject $scope.newProject
      .then (identity) ->
        currentProfileId = identity.currentProfileId
        return $scope.loadProjects()
      .then () ->
        rmapsProfilesService.setCurrentProfileByProfileId currentProfileId

  $scope.loadMap = (project) ->
    $state.go 'map', project_id: project.id, {reload: true}

  $scope.deleteProject = (project) ->
    if project.sandbox
      $scope.modalTitle = "Do you really want to clear your Sandbox?"
    else
      $scope.modalTitle = "Do you really want to delete \"#{project.name}\"?"

    $scope.modalBody = "All notes, drawings, pins and favorites will be discarded"

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()

    $scope.modalCancel = () ->
      modalInstance.dismiss('cancel')

    $scope.modalOk = () ->
      modalInstance.dismiss('ok')
      currentProfileId = null

      rmapsProjectsService.delete project
      .then (identity) ->
        currentProfileId = identity.currentProfileId
        return $scope.loadProjects
      .then () ->
        rmapsProfilesService.setCurrentProfileByProfileId currentProfileId

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
