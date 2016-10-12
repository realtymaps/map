app = require '../app.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

module.exports = app.factory 'rmapsLoginFactory', (
$rootScope
$location
$log
$state
rmapsPrincipalService
rmapsProfilesService
rmapsEventConstants
rmapsLoginHack
rmapsMapAuthorizationFactory
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
        rmapsProfilesService.setCurrentProfileByIdentity data.identity
        .then () ->
          cb = () ->
            rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)
          rmapsLoginHack.checkLoggIn(cb)
          # Currently we can not go directly to login as the session is not synced
          # rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)
      .catch (response) ->
        loginFailed(response)

    return $scope
