backendRoutes = require '../../../../common/config/routes.backend.coffee'
StackTrace = require 'stacktrace-js'
mod = require '../module.coffee'
_ = require 'lodash'
uuid = require 'node-uuid'

MINIMUM_WAIT = 1 # seconds between reports

mod.service 'rmapsErrorHandler', ($log, $injector) ->
  $log = $log.spawn 'rmapsErrorHandler'

  _onerror = null
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

        file ?= stack?[0]?.fileName
        line ?= stack?[0]?.lineNumber
        col  ?= stack?[0]?.columnNumber

        postData = {
          errorRef
          msg
          file
          line
          col
          stack
          count
          url: location.href
          mapped: stack?[0]?.fileName?.indexOf("http") != 0
        }

        StackTrace.report postData, backendRoutes.errors.browser, null, { headers: {} }
        .then (response) ->
          $log.debug response

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
    report({error, msg: error.message})
  , MINIMUM_WAIT*1000 # prevents $digest error spam
