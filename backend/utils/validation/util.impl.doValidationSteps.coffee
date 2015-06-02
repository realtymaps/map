_ = require 'lodash'
Promise = require "bluebird"
logger = require '../../config/logger'
analyzeValue = require '../../../common/utils/util.analyzeValue'

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
  else
    # or just a singleton
    return transform(param, value, index, length)

module.exports = doValidationSteps
