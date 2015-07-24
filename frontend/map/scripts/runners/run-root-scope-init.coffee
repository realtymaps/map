app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

# there are some values we want to save onto the root scope
app.run ($rootScope, $state, $stateParams, $timeout, rmapsprincipal, rmapsSpinner, rmapsevents) ->
    $rootScope.alerts = []
    $rootScope.adminRoutes = adminRoutes
    $rootScope.frontendRoutes = frontendRoutes
    $rootScope.backendRoutes = backendRoutes
    $rootScope.principal = rmapsprincipal
    $rootScope.$state = $state
    $rootScope.$stateParams = $stateParams
    $rootScope.Spinner = rmapsSpinner
    $rootScope.stateData = []

    # evaluate any scopeData routines that have built up upon login
    $rootScope.$onRootScope rmapsevents.principal.login.success, () ->
      $timeout () ->
        while $rootScope.stateData.length
          $rootScope.stateData.pop()()

    # Since controller logic is evaluated when accessing the respective states (like via navbar)
    #   we need to register any controller logic that involves things like API calls that require auth.
    #   This way we can handle that logic after login, and it will not run over and over just by state changes.
    $rootScope.registerScopeData = (restoreState) ->

      # if page is refreshed, but we change states, this will run the restoreState logic if auth'ed instead of pushing
      if rmapsprincipal.isIdentityResolved() && rmapsprincipal.isAuthenticated()
        return restoreState()

      # if not auth'ed, push to container to be evaluated later
      # due to nature of $states, we don't need to worry about multiple restoreStates from one controller bloating here
      $rootScope.stateData.push restoreState
