Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'

module.exports = (options = {truthy: "true", falsy: "false"}) ->

  if Array.isArray(options.truthy)
    truthy = options.truthy
  else if options.truthy?
    truthy = [options.truthy]

  if Array.isArray(options.falsy)
    falsy = options.falsy
  else if options.falsy?
    falsy = [options.falsy]

  outputValues =
    true: options.truthyOutput || true
    false: options.falsyOutput || false

  truthyReturnValue = !options.invert && true
  truthyOutput = outputValues[truthyReturnValue]
  falsyOutput = outputValues[!truthyReturnValue]

  if 'other' of options
    otherReturnValue = options.other

  (param, value) -> Promise.try () ->
    if !value?
      return null

    if options.forceLowerCase && typeof(value) == 'string'
      value = value.toLowerCase()

    if truthy == undefined
      if value
        return truthyOutput
    else if value in truthy
      return truthyOutput

    if falsy == undefined
      if !value
        return falsyOutput
    else if value in falsy
      return falsyOutput

    if otherReturnValue != undefined
      return otherReturnValue

    throw new DataValidationError('invalid value given for boolean field', param, value)
