app = require '../app.coffee'
module.exports = app
moment = require 'moment'

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
  $scope.isSandbox = (project) ->
    !project.sandbox

  $scope.isArchived = (project) ->
    project.archived

  setScopeVariables = () ->
    rmapsPrincipalService.getIdentity()
    .then (identity) ->
      $scope.projects = _.values identity.profiles
      $log.debug $scope.projects
      $scope.totalProjects = $scope.projects.length
      _.each $scope.projects, (project) ->
        project.modified = moment(project.rm_modified_time)
        project.totalProperties = (_.keys project.properties_selected)?.length
        project.totalFavorites = (_.keys project.favorites)?.length

  setScopeVariables()

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    setScopeVariables()

  $scope.selectProject = (project) ->
    $log.debug 'selectProject: ', project

    $scope.projectDropdown.isOpen = false
    rmapsProfilesService.setCurrentProfileByProjectId project.project_id
    .then ->
      if $state.current.projectParam?
        $state.go $state.current, "#{$state.current.projectParam}": project.project_id, reload: true
      else
        $state.go $state.current, $state.current.params, reload: true

  $scope.addProject = () ->
    $scope.newProject =
      copyCurrent: true
      name: (rmapsProfilesService.currentProfile.name or 'Sandbox') + ' copy'

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

  $scope.resetProject = (project) ->
    if confirm 'Clear all filters, saved properties, and notes?'
      rmapsProjectsService.delete id: project.project_id
      .then () ->
        $window.location.reload()