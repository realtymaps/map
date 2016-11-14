app = require '../app.coffee'

app.controller 'rmapsAddProjectController', (
$scope
$log
$uibModal
rmapsProfilesService
rmapsProjectsService) ->
  $log = $log.spawn('rmapsAddProjectController')

  $log.debug -> 'init'

  $scope.addProject = (isCopy) ->
    $scope.newProject =
      if isCopy
        copyCurrent: isCopy
        name: (rmapsProfilesService.currentProfile.name or 'Sandbox') + ' copy'
        modalTitle: "Save Copy of " + (rmapsProfilesService.currentProfile.name or 'Sandbox')
        saveButtonLabel: "Save Project"
      else
        copyCurrent: isCopy
        name: 'New Project'
        modalTitle: "Create a New Blank Project"
        saveButtonLabel: "Create Project"

    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/addProjects.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')
      rmapsProjectsService.createProject $scope.newProject
      .then (identity) ->
        $scope.selectProject(identity.profiles[identity.currentProfileId])
