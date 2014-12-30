Promise = require "bluebird"
logger = require '../config/logger'
ParamValidationError = require './validation/util.error.paramValidation'
loadSubmodules = (require './util.loaders').loadSubmodules
path = require 'path'
doValidation = require './validation/util.impl.doValidation'

    
module.exports =
  query:
    # arguments:
    #   - a map of param names to param values
    #   - a map of param names to validations/transforms to apply; a validation/transform is a function with the
    #     prototype (paramName, paramValue), which returns a promise resolving to the transformed value of the param or
    #     rejecting a non-conforming value.  An array of validations/transforms is also considered a
    #     validation/transform.  If an array is passed, the validators within are iteratively applied as per _.reduce().
    #   - an optional map of params names which are required to have defined values after transformation.  If a mapped
    #     param is undefined after transformation, the value of that param in this map will be used as a default;
    #     validation will be rejected if the value of the param is also undefined in this map
    # returns:
    #     a promise that is resolved with a new map of the (optionally) transformed params, or is rejected if any of
    #     the params failed validation or a required param is undefined at the end of all operations
    validateAndTransform: (params, transforms, required) -> Promise.try () ->
      promises = {}
      # first, do validation/transformation for each param in the map
      for param,value of params
        promises[param] = doValidation(transforms[param], param, value)
      Promise.props(promises)
      .then (transformed) ->
        # check required params
        if not required
          return transformed
        for param,defaultValue of required
          if transformed[param] isnt undefined then continue
          if defaultValue is undefined
            # there is no default to use, so reject
            return Promise.reject new ParamValidationError("required", param, undefined)
          else
            transformed[param] = defaultValue
        return transformed
    
    ParamValidationError: ParamValidationError
    validators: loadSubmodules(path.join(__dirname, 'validation'), /^util\.validation\.(\w+)\.coffee$/)
