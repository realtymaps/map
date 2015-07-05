app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
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
        console.log "#### login success:"
        console.log "data:"
        console.log data
        console.log "status:"
        console.log status
        if !httpStatus.isWithinOK status
          console.log "#### !isWithinOK !"
          return
        $rootScope.$emit rmapsevents.alert.dismiss, alertIds.loginFailure
        rmapsprincipal.setIdentity(data.identity)
        $location.replace()
        console.log "#### doLoginPost, adminRoutes:"
        console.log adminRoutes
        l = $location.search().next || adminRoutes.urls.home
        console.log "#### next loc:"
        console.log l
        $location.url(l)

app.run ($rootScope, $location, rmapsprincipal) ->

  doNextRedirect = (toState, nextLocation) ->
    if rmapsprincipal.isAuthenticated()
      console.log "#### login, doNextRedirect:  isAuthenticated!"
      console.log "#### doNextRedirect toState:"
      console.log toState
      $location.replace()
      console.log "#### doNextRedirect, adminRoutes:"
      console.log adminRoutes
      $location.url(nextLocation || adminRoutes.urls.home)

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
    console.log "#### toState?.url != adminRoutes.login  #{toState.url} != #{adminRoutes.login}?"
    console.log (toState?.url != adminRoutes.login)
    if toState?.url != adminRoutes.login #toState.url is really just the state name here in admin
      return

    # ... and we're already logged in, we'll move past the login state (now or when we find out)
    if rmapsprincipal.isIdentityResolved()
      console.log "#### identity resolved! next redirect: #{toState.url}"
      doNextRedirect(toState, $location.search().next)
    else
      console.log "#### identity not resolved, resolving..."
      rmapsprincipal.getIdentity()
      .then (d) ->
        console.log "#### from rmapsprincipal.getIdentity:"
        console.log d
        doNextRedirect(toState, $location.search().next)
