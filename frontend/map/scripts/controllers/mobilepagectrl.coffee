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
        $scope.profile = profile

        # Load the Project counts such as number of properties, neighborhoods, etc...
        rmapsProjectsService.getProject profile.project_id
        .then (project) ->
          project.propertiesTotal = _.keys(project.properties_selected).length
          $scope.project = project

        # If Editor, retrieve the clients for the project
        $scope.clients = null
        if rmapsprincipal.isProjectEditor()
          clientsService = new rmapsClientsService profile.project_id
          clientsService.getAll()
          .then (clients) ->
            angular.forEach clients, (client) ->
              client.initials = ''
              client.initials += client.first_name[0] if client.first_name
              client.initials += client.last_name[0] if client.last_name

            $scope.clients = clients

      rmapsprincipal.getIdentity()
      .then (identity) ->
        $scope.projectTotal = _.keys(identity.profiles).length
    else
      $scope.projectTotal = null
      $scope.project = null
      $scope.clients = null

  $scope.closeMobileNav = (event) ->
    return if !$scope.isMobileNavOpen
    event.stopPropagation()
    $scope.isMobileNavOpen = false
