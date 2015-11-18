app = require '../app.coffee'

module.exports = app.controller 'MobilePageCtrl', ($scope, rmapsprincipal, rmapsProjectsService, rmapsClientsService) ->
  $scope.isMobileNavOpen = false

  $scope.toggleMobileNav = (event) ->
    event.stopPropagation() if event
    $scope.isMobileNavOpen = !$scope.isMobileNavOpen

  $scope.openMobileNav = (event) ->
    return if $scope.isMobileNavOpen
    event.stopPropagation()
    $scope.isMobileNavOpen = true

    # Load the current project, if any, in order to populate totals in the menu
    if rmapsprincipal.isAuthenticated()
      rmapsprincipal.getCurrentProfile()
      .then (profile) ->
        rmapsProjectsService.getProject profile.project_id
        .then (project) ->
          project.propertiesTotal = _.keys(project.properties_selected).length

          $scope.project = project

      rmapsprincipal.getIdentity()
      .then (identity) ->
        $scope.projectTotal = _.keys(identity.profiles).length

  $scope.closeMobileNav = (event) ->
    return if !$scope.isMobileNavOpen
    event.stopPropagation()
    $scope.isMobileNavOpen = false
