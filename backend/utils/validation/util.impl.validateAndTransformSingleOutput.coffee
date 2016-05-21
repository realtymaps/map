_ = require 'lodash'
Promise = require 'bluebird'
logger = require('../../config/logger').spawn('utils:validation')
doValidationSteps = require './util.impl.doValidationSteps'
DataValidationError = require '../errors/util.error.dataValidation'
noop = require './util.validation.noop'

module.exports = (params, output, definition) -> Promise.try () ->
  if _.isArray(definition) || _.isFunction(definition)
    # shortcut syntax was used
    definition = {transform: definition}
  input = definition.input || output
  transform = definition.transform || noop
  required = definition.required
  isRoot = definition.isRoot ? false

  if isRoot
    values = params
  else if _.isString(input)
    values = params[input]
  else if _.isArray(input)
    values = _.at(params, input)
  else
    values = _.mapValues input, (sourceName) -> params[sourceName]

  doValidationStepsFn = () ->
    doValidationSteps(transform, output, values)
    .then (transformed) ->
      # check for required value
      if required && !transformed?
        throw new DataValidationError('required', output, undefined)
      else
        if !isRoot || !input?
          return transformed
        input = null
        doValidationStepsFn(noop, output, transformed)
  doValidationStepsFn()
