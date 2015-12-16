Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
_ = require 'lodash'
logger = require '../../config/logger'

module.exports = (options = {truthy: "true", falsy: "false"}) ->
  if !_.isArray(options.truthy) && options.truthy != undefined
    truthy = [options.truthy]
  if !_.isArray(options.falsy) && options.falsy != undefined
    falsy = [options.falsy]
  truthyReturnValue = if options.invert? then !options.invert else true

  (param, value) -> Promise.try () ->
    if !value?
      return null

    if options.forceLowerCase && typeof(value) == 'string'
      value = value.toLowerCase()

    if truthy == undefined
      if value
        # logger.debug value
        # logger.debug 'returning truthy undefined'
        return truthyReturnValue
    else if value in truthy
      # logger.debug 'returning truthy'
      return truthyReturnValue
    if falsy == undefined
      if value or value == false
        # logger.debug 'returning falsy undefined'
        return !truthyReturnValue
    else if value in falsy
      # logger.debug 'returning falsy'
      return !truthyReturnValue

    return Promise.reject new DataValidationError('invalid data type given for boolean field', param, value)
