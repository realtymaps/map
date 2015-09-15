_ = require 'lodash'

beforeEach ->
  window.isTest = true

  angular.module('rmapsCommon')
  .config ($provide) ->
    $provide.decorator '$timeout', ($delegate, $browser) ->
      $delegate.hasPendingTasks = ->
        $browser.deferredFns.length > 0

      $delegate

  .service 'digestor', ($rootScope, $timeout, $log) ->
    digest: (scope = $rootScope, fn = ->) ->
      if _.isFunction scope
        fn = scope
        scope = $rootScope

      while $timeout.hasPendingTasks()
        # $log.debug 'FLUSHING!'
        $timeout.flush()

      fn() if fn?
      scope.$digest() unless scope.$$phase
