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
        user = data.identity.user
        user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ''
        user.name = user.full_name or user.username
        $rootScope.user = user
        $rootScope.profiles = data.identity.profiles

        $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
        rmapsPrincipalService.setIdentity(data.identity)
        rmapsProfilesService.setCurrentProfileByIdentity data.identity
        .then () ->
          cb = () ->
            rmapsMapAuthorizationFactory.goToPostLoginState()
          rmapsLoginHack.checkLoggIn(cb)
          # Currently we can not go directly to login as the session is not synced
          # rmapsMapAuthorizationFactory.goToPostLoginState(clear: true)
      .catch (response) ->
        loginFailed(response)

    return $scope
