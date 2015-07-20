app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.config ['$provide', ($provide) ->
  #recommended way of dealing with clean up of angular communication channels
  #http://stackoverflow.com/questions/11252780/whats-the-correct-way-to-communicate-between-controllers-in-angularjs
  $provide.decorator '$rootScope', ($delegate) ->
    Object.defineProperty $delegate.constructor::, '$onRootScope',
      value: (name, listener) ->
        unsubscribe = $delegate.$on(name, listener)
        @$on '$destroy', unsubscribe
        unsubscribe

      enumerable: false

    $delegate
]

# there are some values we want to save onto the root scope
app.run ($rootScope, $state, $stateParams, rmapsprincipal, rmapsSpinner, rmapsevents) ->
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

app.run [ '$rootScope', 'Restangular', 'rmapsevents',
    ($rootScope, Restangular, rmapsevents) ->
      Restangular.setErrorInterceptor (response, deferred, responseHandler) ->
        if response.status == 500
          console.log(response)
          $rootScope.$emit rmapsevents.alert.spawn, response.data.alert
          false
        true
]
