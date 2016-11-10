_ = require 'lodash'
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

  $scope.getModified = (project) -> moment(project.rm_modified_time)

  $scope.selectProject = (project_id) ->
    $log.debug 'selectProject: ', project_id

    $scope.projectDropdown.isOpen = false

    if !project_id
      return
    # if we're currently on the map state, use the rmapsPage.goToMap() function
    if $state.current.name == 'map'
      rmapsPageService.goToMap({project_id})
    else
      # Reset the project and reload the current state
      if $state.current.projectParam?
        $state.go $state.current, "#{$state.current.projectParam}": project_id, reload: true
      else
        $state.go $state.current, $state.current.params, reload: true

  $scope.checkSubmit = (evt) ->
    if evt.keyCode == 13
      $scope.saveProject()

  $scope.archiveProject = (project) ->
    project.archived = !project.archived
    rmapsProjectsService.update project.project_id, _.pick project, 'archived'

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
      rmapsProjectsService.delete profile
      .then () ->
        $scope.selectProject(profile.project_id)

  $scope.resetSandbox = () ->
    sandboxProfile = _.find $rootScope.identity.profiles, 'sandbox', true
    $scope.resetProject(sandboxProfile)

  $scope.setDefaultName = ({project, defaultName, inverseName, isCopy = false}) ->
    copyName = ($scope.principal.getCurrentProfile().name || defaultName) + ' copy'

    if project.name == inverseName && isCopy
      project.name = copyName
    else if project.name == inverseName || project.name == copyName
      project.name = defaultName
