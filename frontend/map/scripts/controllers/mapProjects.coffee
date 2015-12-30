app = require '../app.coffee'
module.exports = app

app.controller 'rmapsMapProjectsCtrl', ($scope, $state, $modal, $window, rmapsProjectsService, rmapsprincipal) ->

  $scope.projectDropdown = isOpen: false

  $scope.selectProject = (project) ->
    $state.go $state.current, 'project_id': project.project_id, { notify: false }
    $scope.projectDropdown.isOpen = false
    $scope.loadProject project

  $scope.addProject = () ->
    $scope.newProject =
      copyCurrent: true
      name: ($scope.selectedProject.name or 'Sandbox') + ' copy'

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
        rmapsprincipal.setIdentity response.data.identity

  $scope.checkSubmit = (evt) ->
    if evt.keyCode == 13
      $scope.saveProject()

  $scope.archiveProject = (project) ->
    rmapsProjectsService.update id: project.project_id, archived: !project.archived
    .then () ->
      $scope.projectDropdown.isOpen = false

  $scope.resetProject = (project) ->
    if confirm 'Clear all filters, saved properties, and notes?'
      rmapsProjectsService.delete id: project.project_id
      .then () ->
        $window.location.reload()
