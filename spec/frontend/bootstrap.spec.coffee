_ = require 'lodash'

beforeEach ->
  window.isTest = true

  angular.module('rmapsCommon')
  .config ($provide) ->
    $provide.value('$log', console)
    $provide.decorator '$timeout', ($delegate, $browser) ->
      $delegate.hasPendingTasks = ->
        $browser.deferredFns.length > 0

      $delegate
    $provide.decorator '$httpBackend', ($delegate) ->

      $delegate.hasPendingRequests = ->
        pending = false
        try
          $delegate.verifyNoOutstandingRequest()
        catch
          pending = true
        pending
      $delegate

  .service 'digestor', ($rootScope, $timeout, $log, $httpBackend) ->
    digest: (scope = $rootScope, fn = ->) ->
      if _.isFunction scope
        fn = scope
        scope = $rootScope

      while $timeout.hasPendingTasks()
        # $log.debug 'FLUSHING!'
        $timeout.flush()

      fn() if fn?
      scope.$digest() unless scope.$$phase

      if $httpBackend.hasPendingRequests()
        # $log.debug "FLUSHING $httpBackend"
        $httpBackend.flush()
