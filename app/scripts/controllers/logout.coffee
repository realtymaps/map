app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

###
  Logout controller
###
module.exports = app.controller 'LogoutCtrl'.ourNs(), () ->

app.run ["$rootScope", "$location", "$http", "$timeout", "principal".ourNs(), 'MainOptions'.ourNs(),
  ($rootScope, $location, $http, $timeout, principal, MainOptions) ->
    $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
      # if we're not entering the logout state, or if we're already on the logout page, don't do anything
      if toState.url != frontendRoutes.logout || fromState.url == frontendRoutes.logout
        return
      minTimestamp = (+new Date)+MainOptions.logoutDelayMillis
      delayedUrl = (url) ->
        $timeout () ->
          $location.replace()
          $location.url url
        , minTimestamp-(+new Date)
      principal.getIdentity()
      .then () ->
        if not principal.isAuthenticated()
          delayedUrl($location.search().next || frontendRoutes.index)
        else
          $http.get backendRoutes.user.logout
          .success (data, status) ->
            principal.unsetIdentity()
            delayedUrl($location.search().next || frontendRoutes.index)
        return
      return
]
