### globals angular, _ ###
app = require '../app.coffee'

module.exports = app.controller 'rmapsMobilePageCtrl', (
  $scope,
  $state,
  $window,
  rmapsClientsFactory,
  rmapsDrawnUtilsService,
  rmapsPageService,
  rmapsPrincipalService,
  rmapsProjectsService,
  rmapsResponsiveViewService
) ->
  #
  # Scope variables
  #

  $scope.isMobileNavOpen = false

  #
  # Determine if this is Desktop or Mobile view
  # Rules should match those defined in responsive.styl
  #

  $scope.mobileView = rmapsResponsiveViewService.isMobileView()
  $scope.desktopView = rmapsResponsiveViewService.isDesktopView()

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
    if rmapsPrincipalService.isAuthenticated()
      if profile = rmapsPrincipalService.getCurrentProfile()
        $scope.profile = profile

        # Load the Project counts such as number of properties, areas, etc...
        rmapsProjectsService.getProject profile.project_id
        .then (project) ->
          project.propertiesTotal = _.keys(project.pins)?.length
          project.favoritesTotal = _.keys(project.favorites)?.length
          $scope.project = project

        # Load Areas
        drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()
        drawnShapesSvc.getAreasNormalized(true)
        .then (data) ->
          $scope.areas = data

        # If Editor, retrieve the clients for the project
        $scope.clients = null
        if rmapsPrincipalService.isProjectEditor()
          clientsService = new rmapsClientsFactory profile.project_id
          clientsService.getAll()
          .then (clients) ->
            angular.forEach clients, (client) ->
              client.initials = ''
              client.initials += client.first_name[0] if client.first_name
              client.initials += client.last_name[0] if client.last_name

            $scope.clients = clients

      rmapsPrincipalService.getIdentity()
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

  $scope.goToMap = () ->
    $scope.closeMobileNav()
    rmapsPageService.goToMap()
