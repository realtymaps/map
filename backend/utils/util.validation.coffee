_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
DataValidationError = require './validation/util.error.dataValidation'
loaders = require './util.loaders'
path = require 'path'
doValidationSteps = require './validation/util.impl.doValidationSteps'


validators = loaders.loadSubmodules(path.join(__dirname, 'validation'), /^util\.validation\.(\w+)\.coffee$/)


validateAndTransformSingleOutput = (params, output, definition) -> Promise.try () ->
  if _.isArray(definition) || _.isFunction(definition)
    # shortcut syntax was used
    definition = {transform: definition}
  input = definition.input || output
  transform = definition.transform || validators.noop
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
      return Promise.reject new DataValidationError("required", output, undefined)
    else
      return transformed

###########
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
###########
# As an alternative use, if the 2nd parameter is an array of definitions instead of a map, each definition has an
# additional, required field:
#       - output: a string giving the output key
# In this case, the return value is a promise that resolves with an array of objects corresponding to the input
# definitions, with the following fields defined:
#       - name: the output key from the definition
#       - value: the transform result of the definition
# This use is intended for cases where the order of the transforms must be maintained.
###########

validateAndTransform = (params, definitions) -> Promise.try () ->
  if _.isArray(definitions)
    promiseList = for definition in definitions
      do (definition) ->
        validateAndTransformSingleOutput(params, definition.output, definition)
        .then (transformed) ->
          name: definition.output
          value: transformed
    Promise.all(promiseList)
    .then (transformedData) ->
      _.filter transformedData, (output) ->
        output.value?
  else
    promiseMap = {}
    for output,definition of definitions
      promiseMap[output] = validateAndTransformSingleOutput(params, output, definition)
    Promise.props(promiseMap)


module.exports =
  validateAndTransform: validateAndTransform
  DataValidationError: DataValidationError
  validators: validators
  doValidationSteps: doValidationSteps
  validateAndTransformSingleOutput: validateAndTransformSingleOutput
