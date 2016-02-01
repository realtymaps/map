mod = require '../module.coffee'
# evaluate any scopeData routines that have built up upon login
mod.service 'rmapsRunnerHelpersService', ($rootScope, $timeout, rmapsPrincipalService, rmapsevents) ->
  setRegisterScopeData: () ->
    $rootScope.$onRootScope rmapsevents.principal.login.success, () ->
      $timeout () ->
        while $rootScope.stateData.length
          $rootScope.stateData.pop()()

    # Since controller logic is evaluated when accessing the respective states (like via navbar)
    #   we need to register any controller logic that involves things like API calls that require auth.
    #   This way we can handle that logic after login, and it will not run over and over just by state changes.
    $rootScope.registerScopeData = (restoreState) ->

      # if page is refreshed, but we change states, this will run the restoreState logic if auth'ed instead of pushing
      if rmapsPrincipalService.isIdentityResolved() && rmapsprincipal.isAuthenticated()
        return restoreState()

      # if not auth'ed, push to container to be evaluated later
      # due to nature of $states, we don't need to worry about multiple restoreStates from one controller bloating here
      $rootScope.stateData.push restoreState
