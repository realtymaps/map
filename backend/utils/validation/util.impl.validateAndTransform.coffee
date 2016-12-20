_ = require 'lodash'
Promise = require 'bluebird'
# coffeelint: disable=check_scope
logger = require('../../config/logger').spawn('utils:impl:validationAndTransform')
# coffeelint: enable=check_scope
validateAndTransformSingleOutput = require './util.impl.validateAndTransformSingleOutput'

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

module.exports = (params, definitions) -> Promise.try () ->
  if !definitions?
    throw new Error 'validateAndTransform: required transform definitions!'

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
