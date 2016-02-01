util = require 'util'
_ = require 'lodash'
Promise = require 'bluebird'
logger = require('../../config/logger').spawn('utils:validation')
analyzeValue = require('../../../common/utils/util.analyzeValue')
doValidationSteps = require './util.impl.doValidationSteps'
DataValidationError = require '../errors/util.error.dataValidation'
noop = require './util.validation.noop'

module.exports = (params, output, definition) -> Promise.try () ->
  # logger.debug "validateAndTransformSingleOutput, arguments:"
  # logger.debug "params=\n#{JSON.stringify(params,null,2)}"
  # logger.debug "output=\n#{JSON.stringify(output,null,2)}"
  # logger.debug "definition=\n#{JSON.stringify(definition,null,2)}"
  # logger.debug "params=\n#{analyzeValue(params)}"
  # logger.debug "output=\n#{analyzeValue(output)}"
  # logger.debug "definition=\n#{analyzeValue(definition)}"
  # logger.debug "params=\n#{util.inspect(params)}"
  # logger.debug "output=\n#{util.inspect(output)}"
  # logger.debug "definition=\n#{util.inspect(definition)}"

  if _.isArray(definition) || _.isFunction(definition)
    # shortcut syntax was used
    definition = {transform: definition}
  input = definition.input || output
  transform = definition.transform || noop
  required = definition.required
  if _.isString(input)
    values = params[input]
  else if _.isArray(input)
    values = _.at(params, input)
  else
    values = _.mapValues input, (sourceName) -> params[sourceName]
  doValidationSteps(transform, output, values)
  .then (transformed) ->
    # check for required value
    if required && !transformed?
      throw new DataValidationError('required', output, undefined)
    else
      return transformed
