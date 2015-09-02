beforeEach ->
  window.isTest = true

  angular.module('rmapsCommon').config ($provide) ->
    $provide.decorator '$timeout', ($delegate, $browser) ->
      $delegate.hasPendingTasks = ->
        $browser.deferredFns.length > 0

      $delegate

    @digest = (scope, $timeout, fn) ->
      hasTimeout = $timeout?.hasPendingTasks?
      if !hasTimeout
        fn = $timeout

      if hasTimeout
        while $timeout.hasPendingTasks()
          $timeout.flush()

      fn() if fn?
      scope.$digest() unless scope.$$phase
