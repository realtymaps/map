Promise = require "bluebird"
logger = require '../config/logger'
DataValidationError = require './validation/util.error.dataValidation'
loaders = require './util.loaders'
path = require 'path'
doValidation = require './validation/util.impl.doValidation'


validators = loaders.loadSubmodules(path.join(__dirname, 'validation'), /^util\.validation\.(\w+)\.coffee$/)


module.exports =
  # arguments:
  #   - a map of param names to param values -- this is the source data
  #   - a map of output keys to validation/transform definitions; a validation/transform definition is an object, with
  #     the following fields (all optional):
  #       - input: a string or an array of strings giving the source key(s) of the input(s).  If it is an array, the
  #         values will be passed to the transform as an array.  If input is falsy, it will default to the output key.
  #       - transform: a function with the prototype (fieldName, fieldValue), which returns a promise resolving to the
  #         transformed value of the field or rejecting a non-conforming value.  An array of validations/transforms is
  #         also considered a validation/transform.  If an array is passed, the validators within are iteratively
  #         applied as per _.reduce().  If transform is falsy, it will default to the noop transform.
  #       - required: if this is truthy and the result of transformation is undefined, transformation will be rejected
  #         with a DataValidationError.
  #     As a syntactic sugar shortcut, if a validation/transform definition is an array or function instead of a
  #     definition object, it will be used as the transform, and the input and required fields will use the defaults.
  # returns:
  #     a promise that is resolved with a map of the transform results, or is rejected if any of the fields failed
  #     validation or a required field is undefined
  validateAndTransform: (params, definitions) -> Promise.try () ->
    promises = {}
    # first, do validation/transformation for each param in the map
    for output,definition of definitions
      if _.isArray(definition) || _.isFunction(definition)
        # shortcut syntax was used
        definition = {transform: definition}
      input = definition.input || output
      transform = definition.transform || validators.noop
      required = definition.required
      if _.isArray(input)
        values = _.at(params, input)
      else
        values = params[input]
      promises[output] = doValidation(transform, output, values)
      .then (transformed) ->
        # check for required value
        if required && transformed == undefined
          return Promise.reject new DataValidationError("required", output, undefined)
        else
          return transformed
    Promise.props(promises)
  
  DataValidationError: DataValidationError
  validators: validators
