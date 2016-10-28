app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

doNextRedirect = (state, toState, nextLocation) ->
  redirectState = state.get(nextLocation || toState)
  state.go(redirectState)

module.exports = app.factory 'rmapsLoginFactory', (
$rootScope
$location
$log
$state
rmapsPrincipalService
rmapsEventConstants
rmapsAdminAuthorizationFactory
rmapsLoginService) ->

  ($scope) ->

    $scope.loginInProgress = false
    $scope.form = {}

    loginFailed = (response) ->
      $log.error "Could not log in", response
      $scope.loginInProgress = false
      $state.go 'login'

    $scope.doLogin = (loginObj) ->
      $scope.loginInProgress = true
      rmapsLoginService.login(loginObj || $scope.form)
      .then ({data, status}) ->

        if !httpStatus.isWithinOK status
          return loginFailed("Bad Status #{status}")
        if !data?.identity?
          return loginFailed("no identity")

        # setting user to $rootScope since this is where a reference to user is used in other parts of the app
        $rootScope.user = data.identity.user
        $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
        rmapsPrincipalService.setIdentity(data.identity)
        doNextRedirect($state, $location.search().next, adminRoutes.mls.replace('/',''))

      .catch (response) ->
        loginFailed(response)

    return $scope
