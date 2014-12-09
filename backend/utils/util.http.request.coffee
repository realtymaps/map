Promise = require "bluebird"
logger = require '../config/logger'
_ = require 'lodash'
status = require '../../common/utils/httpStatus'
analyzeValue = require '../../common/utils/util.analyzeValue'

cleanQuery = (query) ->
  _.each query, (value,key) ->
    query[key] = decodeURIComponent value

doValidation = (transform, param, value, index, length) -> Promise.try () ->
  if not transform
    return value    
  if _.isArray transform
    # can be an array of transforms/validations to reduce over
    return Promise.reduce transform, ((value, subtransform) -> subtransform(param, value, index, length)), value
  else
    # or just a singleton
    return transform(param, value, index, length)

class ParamValidationError extends Error
  constructor: (@message, @paramName, @paramValue) ->
    @name = "ParamValidationError"
    Error.captureStackTrace(this, ParamValidationError)
    analysis = analyzeValue(@paramValue)
    @message = "error validating param <#{@paramName}> with value <#{analysis.type}"+(if analysis.details then ": #{analysis.details}" else "")+"> (#{@message})"
    
module.exports =
  query:
    params:
      cleanQuery: cleanQuery

      toObject: (params, paramsObj = {}) ->
        params.forEach (p)->
          paramsObj[p] = true
        paramsObj

      isAllowed: (query, qAllowedObj, fnName, allowed = false,badKeys = [])->
        fnName = if fnName then "#{fnName} ->" else ""
        query = _.clone query, true
        logger.log "debug", "#{fnName} query: %j", query, {}
        if _.keys(query).length
          allowed = _.all query, (value, key) ->
            unless qAllowedObj[key]
              badKeys.push key
              return false
            true
          # query = cleanQuery query
          allowed: allowed
          badKeys: badKeys

    #iterate through all params and transform / map each value back to the obj[param]
    transform: (obj, transforms, next) ->
      transforms.forEach (t) ->
        if obj[t.param]?
          obj[t.param] = t.transform(obj[t.param],next)
          logger.debug "transform: #{obj}"
      obj

    execute: (isAllowedObj, next, res, execFn)->
      allowed = isAllowedObj.allowed
      badKeys = isAllowedObj.badKeys

      if allowed
        return execFn()
      
      msg = if badKeys.length then "Query Params invalid! #{JSON.stringify badKeys}"
      else "Query Params empty!"
      
      next status:status.BAD_REQUEST, message: msg
    
    ParamValidationError: ParamValidationError
    
    # arguments:
    #   - a map of param names to param values
    #   - a map of param names to validations/transforms to apply; a validation/transform is a function with the
    #     prototype (paramName, paramValue, which returns a promise resolving to the transformed value of the param or
    #     rejecting a non-conforming value.  Also acceptable is an array of such functions.  If an array is passed,
    #     the validators are iteratively applied as per _.reduce().  A validator/transformation is only called if
    #     the param name is present as a key in the original param map.
    #   - an optional map of params to booleans indicating which params are required to have values after transformation
    # ; returns a promise that is resolved
    # with a new map of the (optionally) transformed params, or is rejected if any of the params failed validation or
    # a required param has an undefined value after transformation
    # a validator/transform 
    validateAndTransform: (params, transforms, required = {}) -> Promise.try () ->
      promises = {}
      for param,value of params
        promises[param] = doValidation(transforms[param], param, value)
      Promise.props(promises)
      .then (transformed) ->
        if not required
          return transformed
        for param of required
          if required[param] and transformed[param] is undefined
            return Promise.reject new ParamValidationError("required", param, undefined)
        return transformed
    
    validators:
      defaults: (options = {}) ->
        (param, value) -> Promise.try () ->
          if _.isArray(options.test) and (value in options.test) || 
              _.isFunction(options.test) and options.test(value) ||
              !_.isArray(options.test) and !_.isFunction(options.test) and !value?
            return options.defaultValue
          else
            return value
      integer: (options = {}) ->
        (param, value) -> Promise.try () ->
          type = typeof(value)
          if value == '' || (type != 'string' and type != 'number')
            return Promise.reject new ParamValidationError("integer value required", param, value)
          numvalue = +value
          if isNaN(numvalue) || numvalue != Math.floor(numvalue)
            return Promise.reject new ParamValidationError("integer value required", param, value)
          if options.min? and numvalue < options.min
            return Promise.reject new ParamValidationError("value less than minimum: #{options.min}", param, value)
          if options.max? and numvalue > options.max
            return Promise.reject new ParamValidationError("value larger than maximum: #{options.max}", param, value)
          return numvalue
      float: (options = {}) ->
        (param, value) -> Promise.try () ->
          if value == ''
            return Promise.reject new ParamValidationError("numeric value required", param, value)
          numvalue = +value
          if isNaN(numvalue)
            return Promise.reject new ParamValidationError("numeric value required", param, value)
          if options.min? and numvalue < options.min
            return Promise.reject new ParamValidationError("value less than minimum: #{options.min}", param, value)
          if options.max? and numvalue > options.max
            return Promise.reject new ParamValidationError("value larger than maximum: #{options.max}", param, value)
          return numvalue
      string: (options = {}) ->
        (param, value) -> Promise.try () ->
          if !_.isString(value)
            return Promise.reject new ParamValidationError("string value required", param, value)
          if options.minLength? and value.length < options.minLength
            return Promise.reject new ParamValidationError("string shorter than minimum length: #{options.minLength}", param, value)
          if options.maxLength? and value.length > options.maxLength
            return Promise.reject new ParamValidationError("string longer than maximum length: #{options.maxLength}", param, value)
          if options.regex?
            regex = new RegExp(options.regex)
            if not regex.test(value)
              return Promise.reject new ParamValidationError("string does not match regex: #{regex}", param, value)
          if (options.forceLowerCase)
            transformedValue = value.toLowerCase()
          else if (options.forceUpperCase)
            transformedValue = value.toUpperCase()
          else
            transformedValue = value
          return transformedValue
      choice: (options = {}) ->
        (param, value) -> Promise.try () ->
          if options.equalsTester?
            choice = _.find(options.choices, options.equalsTester.bind(null, value))
            if choice?
              return choice
          else if value in options.choices
            return value
          return Promise.reject new ParamValidationError("unrecognized value, options are: #{JSON.stringify(options.choices)}", param, value)
      array: (options = {}) ->
        (param, values) -> Promise.try () ->
          if options.split? and _.isString(values)
            arrayValues = values.split(options.split)
          else
            arrayValues = values
          if !_.isArray arrayValues
            return Promise.reject new ParamValidationError("array of values expected", param, values)
          if options.minLength? and arrayValues.length < options.minLength
            return Promise.reject new ParamValidationError("array smaller than minimum: #{options.minLength}", param, values)
          if options.maxLength? and arrayValues.length > options.maxLength
            return Promise.reject new ParamValidationError("array larger than maximum: #{options.maxLength}", param, values)
          if options.subValidation
            # subValidation can be any validation/transformation suitable for use in validateAndTransform() (including
            # an array of iteratively applied functions), except these validators are also passed the index and length
            # of the array as additional paramters
            return Promise.map arrayValues, doValidation.bind(null, options.subValidation, param)
          else
            return arrayValues
      catchValidationRejection: (options = {}) ->
        (param, value) -> Promise.try () ->
          doValidation(options.subValidation, param, value)
          .catch ParamValidationError, () ->
            Promise.resolve(options.defaultValue)
