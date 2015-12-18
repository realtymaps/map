app = require '../app.coffee'

module.exports = app.controller 'MobilePageCtrl', ($scope, $state, $window, rmapsprincipal, rmapsProjectsService, rmapsClientsService, rmapsResponsiveView) ->
  #
  # Scope variables
  #

  $scope.isMobileNavOpen = false

  #
  # Determine if this is Desktop or Mobile view
  # Rules should match those defined in responsive.styl
  #

  $scope.mobileView = rmapsResponsiveView.isMobileView()
  $scope.desktopView = rmapsResponsiveView.isDesktopView()

  #
  # Mobile Menu Events
  #

  $scope.toggleMobileNav = (event) ->
    event.stopPropagation() if event
    $scope.isMobileNavOpen = !$scope.isMobileNavOpen

  $scope.openMobileNav = (event) ->
    return if $scope.isMobileNavOpen
    event.stopPropagation()
    $scope.isMobileNavOpen = true

    # Load the current project, if any, in order to populate totals in the menu
    if rmapsprincipal.isAuthenticated()
      if profile = rmapsprincipal.getCurrentProfile()
        $scope.profile = profile

        # Load the Project counts such as number of properties, neighbourhoods, etc...
        rmapsProjectsService.getProject profile.project_id
        .then (project) ->
          project.propertiesTotal = _.keys(project.properties_selected)?.length
          project.favoritesTotal = _.keys(project.favorites)?.length
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
    event.stopPropagation() if event
    $scope.isMobileNavOpen = false

  #
  # Mobile Menu Navigation - Handles closing menu if open
  #

  $scope.goToState = (state, params, options) ->
    $scope.closeMobileNav()
    $state.go state, params, options
