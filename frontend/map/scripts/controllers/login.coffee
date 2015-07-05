app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

###
  Login controller
###

module.exports = app.controller 'rmapsLoginCtrl',
  ($rootScope, $scope, $http, $location, rmapsprincipal, rmapsevents) ->

    $scope.form = {}
    $scope.doLoginPost = () ->
      $http.post backendRoutes.userSession.login, $scope.form
      .success (data, status) ->
        if !httpStatus.isWithinOK status
          return
        $rootScope.$emit rmapsevents.alert.dismiss, alertIds.loginFailure
        rmapsprincipal.setIdentity(data.identity)
        $location.replace()
        $location.url($location.search().next || frontendRoutes.map)

app.run ($rootScope, $location, rmapsprincipal) ->

  doNextRedirect = (toState, nextLocation) ->
    if rmapsprincipal.isAuthenticated()
      $location.replace()
      $location.url(nextLocation || frontendRoutes.map)

  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    console.log "#### $stateChangeStart"
    console.log "#### event:"
    console.log event
    console.log "#### toState:"
    console.log toState
    console.log "#### toParams:"
    console.log toParams
    console.log "#### fromState:"
    console.log fromState
    console.log "#### fromParams:"
    console.log fromParams

    # if we're entering the login state...
    console.log "#### toState?.url != frontendRoutes.login  #{toState.url} != #{frontendRoutes.login}?"
    console.log (toState?.url != frontendRoutes.login)
    if toState?.url != frontendRoutes.login
      return

    # ... and we're already logged in, we'll move past the login state (now or when we find out)
    if rmapsprincipal.isIdentityResolved()
      console.log "#### identity resolved! next redirect: #{toState.url}"
      doNextRedirect(toState, $location.search().next)
    else
      console.log "#### identity not resolved, resolving..."
      rmapsprincipal.getIdentity()
      .then () ->
        console.log "#### from rmapsprincipal.getIdentity:"
        console.log d
        doNextRedirect(toState, $location.search().next)
