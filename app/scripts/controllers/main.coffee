app = require '../app.coffee'

require '../runners/run-templates.coffee'
require '../runners/run.coffee'
require '../config/location.coffee'
require '../config/on-root-scope.coffee'
require '../config/routes.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

module.exports = app.controller 'MainCtrl'.ourNs(), [ 'uiGmapLogger', 'Limits'.ourNs(), ($log, limitsPromise) ->
  limitsPromise.then (limits) ->
    $log.doLog = limits.doLog
]

app.run ["$rootScope", "principal".ourNs(), ($rootScope, principal) ->

  $rootScope.frontendRoutes = frontendRoutes;
  
  $rootScope.principal = principal;
  #bootstrap the idenitity check when the app loads
  principal.getIdentity()
  
  $rootScope.$on "$routeChangeStart", (event, nextRoute) ->
    console.log("$routeChangeStart: #{nextRoute?.$$route?.originalPath}")
]
