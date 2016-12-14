_ = require 'lodash'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('utils:validation')
# coffeelint: enable=check_scope
DataValidationError = require './errors/util.error.dataValidation'
loaders = require './util.loaders'
doValidationSteps = require './validation/util.impl.doValidationSteps'
validateAndTransformSingleOutput = require './validation/util.impl.validateAndTransformSingleOutput'
validateAndTransform = require './validation/util.impl.validateAndTransform'
validators = loaders.loadSubmodules(__dirname, './validation', /^util\.validation\.(\w+)\.coffee$/)

###
  Does the same as validateAndTransform, but also removes all properties
   from validated result that were originally undefined/null.
  Useful for keeping API updates from nullifying values that weren't part of the request
###
validateAndTransformRequest = (params, definitions) ->
  removeMissing = (params, req) ->
    #TODO This is not always ideal see validation.mapKeys and or using input to remap
    #thinking of adding an ignore list, with parent key
    # coffeelint: disable=check_scope
    for k, v of params
    # coffeelint: enable=check_scope
      if !req[k]?
        delete params[k]
      else if _.isObject(params[k]) and _.isObject(req[k])
        params[k] = removeMissing params[k], req[k]
    params

  validateAndTransform arguments...
  .then (valid) ->
    removeMissing valid, params

###
  Noop the default transforms for a Crud Request
###
defaultRequestTransforms = (obj) ->
  def = {
    params: validators.noop
    query: validators.noop
    body: validators.noop
  }

  return def unless obj

  # coffeelint: disable=check_scope
  for key, val of def
  # coffeelint: enable=check_scope
    obj[key] = if obj[key]? then obj[key] else def[key]
  obj


###
  Noop All transforms if Falsy
###
falsyTransformsToNoop = (transforms) ->
  for key, val of transforms
    transforms[key] = validators.noop unless val

  transforms

falsyDefaultTransformsToNoop = (transforms) ->
  falsyTransformsToNoop(defaultRequestTransforms(transforms))

requireAllTransforms = (definitions, excludes) ->
  for key, tran of definitions
    if _.isFunction tran #TODO handle arrays
      if !tran.notRequired and (!excludes? or excludes.indexOf(key) < 0)
        definitions[key] =
          transform: tran
          required: true

      if tran.notRequired
        delete tran.notRequired
      continue
    tran.required = true
  definitions

notRequired = (transform) ->
  transform.notRequired = true
  transform

required = (transform) ->
  transform: transform
  required: true

module.exports =
  validateAndTransform: validateAndTransform
  validateAndTransformRequest: validateAndTransformRequest
  DataValidationError: DataValidationError
  validators: validators
  doValidationSteps: doValidationSteps
  validateAndTransformSingleOutput: validateAndTransformSingleOutput
  falsyTransformsToNoop:falsyTransformsToNoop
  defaultRequestTransforms : defaultRequestTransforms
  falsyDefaultTransformsToNoop: falsyDefaultTransformsToNoop
  requireAllTransforms: requireAllTransforms
  notRequired: notRequired
  required: required
