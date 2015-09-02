mod = require '../module.coffee'

mod.service 'rmapsRendering', ($timeout) ->
  debounce: (stateObj, fn, delayMilliSecs) ->
    if stateObj
      $timeout.cancel(@filterDrawPromise)

    stateObj = $timeout ->
      fn()
      stateObj = false
    , delayMilliSecs
