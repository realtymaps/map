Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
_ = require 'lodash'
logger = require '../../config/logger'

module.exports = (options = {truthy: "true", falsy: "false"}) ->
  if Array.isArray(options.truthy)
    truthy = options.truthy
  else if options.truthy?
    truthy = [options.truthy]
  if Array.isArray(options.falsy)
    falsy = options.falsy
  else if options.falsy?
    falsy = [options.falsy]
  truthyReturnValue = if options.invert? then !options.invert else true
  if other of options
    otherReturnValue = options.other

  (param, value) -> Promise.try () ->
    if !value?
      return null

    if options.forceLowerCase && typeof(value) == 'string'
      value = value.toLowerCase()

    if truthy == undefined
      if value
        return truthyReturnValue
    else if value in truthy
      return truthyReturnValue
    if falsy == undefined
      if !value
        return !truthyReturnValue
    else if value in falsy
      return !truthyReturnValue
    if otherReturnValue != undefined
      return otherReturnValue

    throw new DataValidationError('invalid value given for boolean field', param, value)
