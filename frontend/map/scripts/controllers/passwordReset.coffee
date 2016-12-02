app = require '../app.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app.controller 'rmapsPasswordResetCtrl', (
  $rootScope,
  $scope,
  $log,
  $state,
  $http,
  rmapsEventConstants,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsMapAuthorizationFactory,
  rmapsResponsiveViewService,
  rmapsLoginHack
) ->
  $log = $log.spawn 'rmapsPasswordResetCtrl'

  mobileView = rmapsResponsiveViewService.isMobileView()

  $scope.login = () ->
    # based on login controller
    $http.post backendRoutes.userSession.doResetPassword, _.merge($scope.client, key: $state.params.key)
    .then ({data, status}) ->
      if !httpStatus.isWithinOK status
        $log.error status

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
            rmapsMapAuthorizationFactory.goToPostLoginState()

        rmapsLoginHack.checkLoggIn(cb)

    , (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false

  $http.get backendRoutes.userSession.getResetPassword, {params: {key: $state.params.key}, alerts: false}
  .then ({data}) ->
    $scope.client = data
  .catch ({data}) ->
    $log.debug data
    $scope.errMsg = data.message