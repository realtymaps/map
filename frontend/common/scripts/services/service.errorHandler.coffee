backendRoutes = require '../../../../common/config/routes.backend.coffee'
StackTrace = require 'stacktrace-js'
mod = require '../module.coffee'
_ = require 'lodash'
uuid = require 'node-uuid'

mod.service 'rmapsErrorHandler', ($log, $injector) ->
  $log = $log.spawn 'rmapsErrorHandler'

  _onerror = null
  _ignoreNextDigest = false
  count = 0

  report = (details = {}) ->
    # $log.debug arguments...
    # https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onerror
    {error, msg, file, line, col} = details

    # If error is not available, stacktrace-js claims to be able to
    # artificially generate a trace. This part is untested
    StackTrace[if error then 'fromError' else 'generateArtificially'](error)
    .then (stack) ->

      if msg || stack?.length

        errorRef = uuid.v1()
        # Will create duplicate console error, but with a reference the user can give support
        $log.error "RealtyMaps error reference", errorRef, msg

        $http = $injector.get('$http') # necessary to avoid circular dependency
        $rootScope = $injector.get('$rootScope')
        user = $rootScope?.identity?.user

        file ?= stack?[0]?.fileName
        line ?= stack?[0]?.lineNumber
        col  ?= stack?[0]?.columnNumber

        $http.post backendRoutes.monitor.error, {
          errorRef
          msg
          file
          line
          col
          email: user?.email
          userid: user?.id
          stack
          count
          url: location.href
        }, { alerts: false }

        count += 1

      _onerror?(msg, file, line, col, error)

    .catch (err) ->
      _onerror?(msg, file, line, col, error)

  captureGlobalErrors: () ->
    _onerror = window.onerror
    window.onerror = (msg, file, line, col, error) ->
      report({msg, file, line, col, error})

  captureAngularException: _.debounce (error) ->
    $log.error error # Will not be logged as usual, so make sure we can see the error in console
    if _ignoreNextDigest # $http calls trigger a $digest, prevent looping
      _ignoreNextDigest = false
      return
    _ignoreNextDigest = true
    report({error, msg: error.message})
  , 1000 # prevents $digest error spam
