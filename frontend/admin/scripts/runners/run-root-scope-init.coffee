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
app.run ($rootScope, $state, $stateParams, $timeout, rmapsprincipal, rmapsSpinner, rmapsevents, rmapsRunnerHelpers) ->
  $rootScope.alerts = []
  $rootScope.adminRoutes = adminRoutes
  $rootScope.frontendRoutes = frontendRoutes
  $rootScope.backendRoutes = backendRoutes
  $rootScope.principal = rmapsprincipal
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams
  $rootScope.Spinner = rmapsSpinner
  $rootScope.stateData = []

  rmapsRunnerHelpers.setRegisterScopeData()

app.run [ '$rootScope', 'Restangular', 'rmapsevents',
    ($rootScope, Restangular, rmapsevents) ->
      Restangular.setErrorInterceptor (response, deferred, responseHandler) ->
        if response.status == 500
          console.log(response)
          $rootScope.$emit rmapsevents.alert.spawn, response.data.alert
          false
        true
]
