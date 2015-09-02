mod = require '../module.coffee'

mod.service 'rmapsRendering', ($timeout) ->
  debounce: (stateObj, propName, fn, delayMilliSecs) ->
    if stateObj?[propName]
      $timeout.cancel(@filterDrawPromise)

    stateObj[propName] = $timeout ->
      fn()
      stateObj[propName] = false
    , delayMilliSecs
