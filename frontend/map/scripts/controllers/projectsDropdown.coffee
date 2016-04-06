app = require '../app.coffee'
module.exports = app

app.controller 'rmapsProjectsDropdownCtrl', (
  $rootScope,
  $scope,
  $state,
  $modal,
  $window,
  $log,
  rmapsEventConstants,
  rmapsProjectsService,
  rmapsProfilesService,
  rmapsPrincipalService
) ->

  $log = $log.spawn 'rmapsProjectsDropdownCtrl'

  $scope.projectDropdown = isOpen: false

  setScopeVariables = () ->
    rmapsPrincipalService.getIdentity()
    .then (identity) ->
      $scope.projects = _.values identity.profiles
      $log.debug $scope.projects
      $scope.totalProjects = $scope.projects.length
      _.each $scope.projects, (project) ->
        project.totalProperties = (_.keys project.properties_selected)?.length
        project.totalFavorites = (_.keys project.favorites)?.length

  setScopeVariables()

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    setScopeVariables()

  $scope.selectProject = (project) ->
    $log.debug 'selectProject: ', project
    # $state.go $state.current, 'project_id': project.project_id, { notify: false }
    $scope.projectDropdown.isOpen = false
    rmapsProfilesService.setCurrentProfileByProjectId project.project_id

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

  $scope.checkSubmit = (evt) ->
    if evt.keyCode == 13
      $scope.saveProject()

  $scope.archiveProject = (project) ->
    project.archived = !project.archived
    rmapsProjectsService.update project.project_id, _.pick project, 'archived'
    .then () ->
      $scope.projectDropdown.isOpen = false

  $scope.resetProject = (project) ->
    if confirm 'Clear all filters, saved properties, and notes?'
      rmapsProjectsService.delete id: project.project_id
      .then () ->
        $window.location.reload()
