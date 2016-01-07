_ = require 'lodash'
Promise = require 'bluebird'
logger = require '../../config/logger'
# analyzeValue = require '../../../common/utils/util.analyzeValue'

doValidationSteps = (transform, param, value, index, length) -> Promise.try () ->
  if not transform
    return value
  if _.isArray transform
    # an array of transforms/validations to reduce over
    return Promise.each transform, (subtransform) ->
      doValidationSteps(subtransform, param, value, index, length)
      .then (result) ->
        value = result
    .then () ->
      return value
  else if _.isArray transform?.any
    promises = transform.any.map (subtransform) ->
      doValidationSteps(subtransform, param, value, index, length)
    return Promise.any promises #pick the first validation that works
  else
    # or just a singleton
    unless _.isFunction transform
      logger.debug transform, true
    return transform(param, value, index, length)

module.exports = doValidationSteps
