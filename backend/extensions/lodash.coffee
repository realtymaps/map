_ = require 'lodash'

_.required = (obj, props, doThrow = false) ->
  ret = true
  for key, value in props
    if !value?
      ret = false
      throw new Error("#{key} is not defined and is required!") if doThrow
      break
  ret
