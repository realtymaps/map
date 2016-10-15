###global _###
app = require '../app.coffee'
module.exports = app
moment = require 'moment'

app.controller 'rmapsProjectsDropdownCtrl', (
  $rootScope,
  $scope,
  $state,
  $uibModal,
  $window,
  $log,
  rmapsEventConstants,
  rmapsPageService,
  rmapsProjectsService,
  rmapsProfilesService,
  rmapsPrincipalService
) ->

  $log = $log.spawn 'rmapsProjectsDropdownCtrl'

  $scope.projectDropdown = isOpen: false
  $scope.isSandbox = (project) ->
    !project.sandbox

  setScopeVariables = () ->
    rmapsPrincipalService.getIdentity()
    .then (identity) ->
      if !identity?.profiles
        return
      $scope.projects = _.values identity.profiles
      $scope.totalProjects = _.filter($scope.projects, (p) -> !p.archived).length

      _.each $scope.projects, (project) ->
        project.modified = moment(project.rm_modified_time)
        project.totalProperties = (_.keys project.pins)?.length
        project.totalFavorites = (_.keys project.favorites)?.length

      $log.debug $scope.projects

  setScopeVariables()

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    setScopeVariables()

  $scope.selectProject = (project) ->
    $log.debug 'selectProject: ', project

    $scope.projectDropdown.isOpen = false

    if !project
      return
    # if we're currently on the map state, use the rmapsPage.goToMap() function
    if $state.current.name == 'map'
      rmapsPageService.goToMap({project_id: project.project_id})
    else
      # Reset the project and reload the current state
      if $state.current.projectParam?
        $state.go $state.current, "#{$state.current.projectParam}": project.project_id, reload: true
      else
        $state.go $state.current, $state.current.params, reload: true

  $scope.checkSubmit = (evt) ->
    if evt.keyCode == 13
      $scope.saveProject()

  $scope.archiveProject = (project) ->
    project.archived = !project.archived
    rmapsProjectsService.update project.project_id, _.pick project, 'archived'
    $scope.totalProjects = _.filter($scope.projects, (p) -> !p.archived).length

  $scope.resetProject = (profile) ->
    return if !profile.sandbox
    $scope.modalTitle = "Are you sure?"
    $scope.modalBody = "Sandbox will be cleared (pinned, favorites, notes and filters)"
    $scope.showCancelButton = true
    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()
    modalInstance.result.then ->
      rmapsProjectsService.delete id: profile.project_id
      .then (identity) ->
        newProfile = _.find identity.profiles, 'id', profile.id
        $scope.selectProject(newProfile)

  $scope.resetSandbox = () ->
    sandboxProfile = _.find $scope.projects, 'sandbox', true
    $scope.resetProject(sandboxProfile)

  $scope.setDefaultName = ({project, defaultName, inverseName, isCopy = false}) ->
    copyName = ($scope.principal.getCurrentProfile().name || defaultName) + ' copy'

    if project.name == inverseName && isCopy
      project.name = copyName
    else if project.name == inverseName || project.name == copyName
      project.name = defaultName
