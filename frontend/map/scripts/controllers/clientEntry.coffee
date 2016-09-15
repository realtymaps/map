app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

module.exports = app.controller 'rmapsClientEntryCtrl', (
  $rootScope,
  $scope,
  $log,
  $state,
  #$http,
  rmapsClientEntryService,
  rmapsEventConstants,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsMapAuthorizationFactory,
  rmapsResponsiveViewService,
  rmapsLoginHack
) ->
  $log = $log.spawn 'rmapsClientEntryCtrl'

  mobileView = rmapsResponsiveViewService.isMobileView()


  # ### BEGIN TERRIBLE HACK !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #   We need to figure out why after login succedes that some post processing routes still think we are not logged in.

  #   Hence why we check backendRoutes.config.protectedConfig as this route is protected by login. We recurse this route until
  #   we are actual logged in.
  # ###
  # isLoggedIn = () ->
  #   $http.get backendRoutes.config.protectedConfig
  #   .then ({data} = {}) ->
  #     if !data || data.doLogin == true
  #       return false
  #     true

  # # just because loggin succeeded does not mean the backend is synced with the profile
  # # check until it is synced
  # checkLoggIn = (maybeLoggedIn) ->
  #   if maybeLoggedIn

  #     if mobileView
  #       $state.go('project', {id: $scope.project.id}, {reload: true})
  #     else
  #       #$state.go('map', {id: $scope.project.id}, {reload: true})
  #       rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)
  #     return

  #   isLoggedIn()
  #   .then (loggedIn) ->
  #     setTimeout ->
  #       checkLoggIn(loggedIn)
  #     , 500

  # # END TERRIBLE HACK !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


  $scope.login = () ->
    $scope.loginInProgress = true

    # based on login controller
    rmapsClientEntryService.setPasswordAndBounce $scope.client
    .then ({data, status}) ->
      if !httpStatus.isWithinOK status
        $scope.loginInProgress = false
        return

      # setting user to $rootScope since this is where a reference to user is used in other parts of the app
      $rootScope.user = data.identity.user
      $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
      rmapsPrincipalService.setIdentity(data.identity)
      rmapsProfilesService.setCurrentProfileByIdentity data.identity
      .then () ->
        cb = () ->
          if mobileView
            $state.go('project', {id: $scope.project.id}, {reload: true})
          else
            #$state.go('map', {id: $scope.project.id}, {reload: true})
            rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)

        rmapsLoginHack.checkLoggIn(cb)

    , (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false

  rmapsClientEntryService.getClientEntry $state.params.key
  .then (data) ->
    $scope.client = data.client
    $scope.parent = data.parent
    $scope.project = data.project
