app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

###
  Login controller
###

module.exports = app.controller 'rmapsLoginCtrl', (
$rootScope
$scope
$http
$location
$log
$state
rmapsPrincipalService
rmapsProfilesService
rmapsEventConstants
rmapsMapAuthorizationFactory) ->

  $scope.loginInProgress = false
  $scope.form = {}

  loginFailed = (response) ->
    $log.error "Could not log in", response
    $scope.loginInProgress = false
    $state.go 'login'

  $scope.doLoginPost = () ->
    $scope.loginInProgress = true
    $http.post backendRoutes.userSession.login, $scope.form
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
        rmapsMapAuthorizationFactory.goToPostLoginState()
    .catch (response) ->
      loginFailed(response)
