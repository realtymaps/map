backendRoutes = require '../../../../common/config/routes.backend.coffee'
StackTrace = require 'stacktrace-js'
mod = require '../module.coffee'
_ = require 'lodash'

mod.service 'rmapsErrorHandler', ($log, $injector) ->
  $log = $log.spawn 'rmapsErrorHandler'

  report = (msg, file, line, col, error, user) ->
    $log.debug arguments...

    $http = $http || $injector.get('$http') # necessary to avoid circular dependency

    StackTrace[if error then 'fromError' else 'generateArtificially'](error)
    .then (frames) ->

      $http.post backendRoutes.monitor.error, {
        error
        msg
        file
        line
        col
        user
        frames
      }, { alerts: false }

      window._onerror?(arguments...)

    .catch (err) ->
      window._onerror?(arguments...)

  captureGlobalErrors: () ->
    window._onerror = window.onerror
    window.onerror = report

  captureAngularException: _.throttle ({exception, cause, user}) ->
    $log.debug 'Angular:', exception
    report(exception.message, exception.file, exception.line, exception.col, exception, user)
  , 2000