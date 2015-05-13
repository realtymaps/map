app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

# there are some values we want to save onto the root scope
app.run ["$rootScope", "$state", "$stateParams", "principal".ourNs(), 'Spinner'.ourNs(),
  ($rootScope, $state, $stateParams, principal, Spinner) ->
    $rootScope.alerts = []
    $rootScope.frontendRoutes = frontendRoutes
    $rootScope.backendRoutes = backendRoutes
    $rootScope.principal = principal
    $rootScope.$state = $state
    $rootScope.$stateParams = $stateParams
    $rootScope.Spinner = Spinner
]
