app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

###
  Login controller
###


doNextRedirect = (state, toState, nextLocation) ->
  redirectState = state.get(nextLocation || toState)
  state.go(redirectState)


module.exports = app.controller 'rmapsLoginCtrl', (

$rootScope
$scope
$http
$log
$location
$state
rmapsPrincipalService
rmapsEventConstants) ->

  loginFailed = (response) ->
    $log.error "Could not log in", response
    $state.go 'login'

  $scope.form = {}
  $scope.doLoginPost = () ->
    $http.post backendRoutes.userSession.login, $scope.form
    .then ({data, status}) ->
      if !httpStatus.isWithinOK(status)
        return loginFailed("Bad Status #{status}")
      if !data?.identity?
        return loginFailed("no identity")

      $rootScope.$emit rmapsEventConstants.alert.dismiss, alertIds.loginFailure
      rmapsPrincipalService.setIdentity(data.identity)

      doNextRedirect($state, $location.search().next, adminRoutes.mls.replace('/',''))
    .catch (response) ->
      loginFailed(response)


app.run (
$rootScope
$location
$state
rmapsPrincipalService) ->

  ###eslint-disable###
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    ###eslint-enable###
    # if we're entering the login state...
    if toState?.url != adminRoutes.login #toState.url is really just the state name here in admin
      return

    # ... and we're already logged in, we'll move past the login state (now or when we find out)

    if rmapsPrincipalService.isAuthenticated()
      if rmapsPrincipalService.isIdentityResolved()
        doNextRedirect($state, toState, $location.search().next)
      else
        rmapsPrincipalService.getIdentity()
        .then () ->
          doNextRedirect($state, toState, $location.search().next)
