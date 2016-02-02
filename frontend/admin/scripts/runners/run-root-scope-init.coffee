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
app.run ($rootScope, $state, $stateParams, $timeout, rmapsPrincipalService, rmapsSpinnerService, rmapsEventConstants, rmapsRunnerHelpersService) ->
  $rootScope.alerts = []
  $rootScope.adminRoutes = adminRoutes
  $rootScope.frontendRoutes = frontendRoutes
  $rootScope.backendRoutes = backendRoutes
  $rootScope.principal = rmapsPrincipalService
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams
  $rootScope.Spinner = rmapsSpinnerService
  $rootScope.stateData = []

  rmapsRunnerHelpersService.setRegisterScopeData()

app.run [ '$rootScope', 'Restangular', 'rmapsEventConstants',
    ($rootScope, Restangular, rmapsEventConstants) ->
      Restangular.setErrorInterceptor (response, deferred, responseHandler) ->
        if response.status == 500
          console.log(response)
          $rootScope.$emit rmapsEventConstants.alert.spawn, response.data.alert
          false
        true
]
