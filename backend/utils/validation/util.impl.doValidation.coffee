Promise = require "bluebird"
logger = require '../../config/logger'

doValidation = (transform, param, value, index, length) -> Promise.try () ->
  if not transform
    return value
  if _.isArray transform
    # an array of transforms/validations to reduce over
    return Promise.reduce transform, ((value, subtransform) -> doValidation(subtransform, param, value, index, length)), value
  else
    # or just a singleton
    return transform(param, value, index, length)

module.exports = doValidation
