app = require '../app.coffee'
runnerHelpers = require '../../../common/scripts/utils/util.runnerHelpers.coffee'
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

    runnerHelpers.setRegisterScopeData($rootScope, $timeout, rmapsprincipal, rmapsevents)
