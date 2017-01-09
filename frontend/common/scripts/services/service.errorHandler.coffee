backendRoutes = require '../../../../common/config/routes.backend.coffee'
StackTrace = require 'stacktrace-js'
mod = require '../module.coffee'
_ = require 'lodash'

mod.service 'rmapsErrorHandler', ($log, $injector) ->
  $log = $log.spawn 'rmapsErrorHandler'

  _onerror = null

  # https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onerror
  report = ({msg, file, line, col, error, user}) ->
    # $log.debug arguments...

    $http = $http || $injector.get('$http') # necessary to avoid circular dependency

    # If error is not available, stacktrace-js claims to be able to artificially generate a trace. Not sure it works
    StackTrace[if error then 'fromError' else 'generateArtificially'](error)
    .then (frames) ->
      if frames?.length
        $http.post backendRoutes.monitor.error, {
          error
          msg
          file
          line
          col
          user
          frames
        }, { alerts: false }

      _onerror?(msg, file, line, col, error)

    .catch (err) ->
      _onerror?(msg, file, line, col, error)

  captureGlobalErrors: () ->
    _onerror = window.onerror
    window.onerror = report

  captureAngularException: _.throttle ({exception, cause, user}) ->
    $log.debug 'Angular:', exception.message
    exception.msg ?= exception.message
    exception.user = user
    report({exception})
  , 2000
