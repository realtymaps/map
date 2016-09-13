app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

module.exports = app.controller 'rmapsClientEntryCtrl', (
  $rootScope,
  $scope,
  $log,
  $state,
  $http,
  $stickyState,
  rmapsClientEntryService,
  rmapsEventConstants,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsMapAuthorizationFactory,
  rmapsResponsiveViewService
) ->
  $log = $log.spawn 'rmapsClientEntryCtrl'

  mobileView = rmapsResponsiveViewService.isMobileView()

  isLoggedIn = () ->
    $http.get backendRoutes.config.protectedConfig
    .then ({data} = {}) ->
      console.log "protectedConfig:\n#{JSON.stringify(data)}"
      if !data || data.doLogin == true
        return false
      true

  # just because loggin succeeded does not mean the backend is synced with the profile
  # check until it is synced
  checkLoggIn = (maybeLoggedIn) ->
    if maybeLoggedIn
      #rmapsMapAuthorizationFactory.goToPostLoginState()

      return

    isLoggedIn()
    .then (loggedIn) ->
      setTimeout ->
        checkLoggIn(loggedIn)
      , 500

  $scope.login = () ->
    $scope.loginInProgress = true

    # based on login controller
    rmapsClientEntryService.setPasswordAndBounce $scope.client
    .then ({data, status}) ->
      console.log "clientLogin data:\n#{JSON.stringify(data)}"
      if !httpStatus.isWithinOK status
        $scope.loginInProgress = false
        return

      # setting user to $rootScope since this is where a reference to user is used in other parts of the app
      $rootScope.user = data.identity.user
      $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
      rmapsPrincipalService.setIdentity(data.identity)
      rmapsProfilesService.setCurrentProfileByIdentity data.identity
      .then () ->
        $stickyState.reset('map')
        if mobileView
          $state.go 'project', id: $scope.project.id
        else
          $state.go('map', {id: $scope.project.id}, {reload: true})

    , (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false


  rmapsClientEntryService.getClientEntry $state.params.key
  .then (data) ->
    $scope.client = data.client
    $scope.parent = data.parent
    $scope.project = data.project
