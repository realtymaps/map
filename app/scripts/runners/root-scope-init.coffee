app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

# there are some values we want to save onto the root scope
app.run ["$rootScope", "principal".ourNs(), ($rootScope, principal) ->
  $rootScope.frontendRoutes = frontendRoutes;
  $rootScope.backendRoutes = backendRoutes;  
  $rootScope.principal = principal;
]
