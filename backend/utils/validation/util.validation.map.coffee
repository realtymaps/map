_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'

# Goal is to map the value of the param to a match mapped value
#
# TODO: rename to mapValues
# use case:
# sold, pending-sale, off-market all map to not-for-sale
#
# * `options  Options with the field map is expected {object}.
#
# Returns the mapped value.
module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !options.map
      return Promise.reject new DataValidationError("no map provided, options are: #{JSON.stringify(options)}", param, value)
    mapped = options.map[value]
    if mapped?
      return mapped
    if !value? || value == ''
      return null
    if options.passUnmapped
      return value
    return Promise.reject new DataValidationError("unmappable value, options are: #{JSON.stringify(_.keys(options.map))}", param, value)
