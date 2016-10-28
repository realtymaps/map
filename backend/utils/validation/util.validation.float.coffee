Promise = require 'bluebird'
_ = require 'lodash'
DataValidationError = require '../errors/util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null
    numvalue = +value
    if isNaN(numvalue)
      return Promise.reject new DataValidationError('invalid data type given for numeric value', param, value)
    if options.min? and numvalue < options.min
      return Promise.reject new DataValidationError("value less than minimum: #{options.min}", param, value)
    if options.max? and numvalue > options.max
      return Promise.reject new DataValidationError("value larger than maximum: #{options.max}", param, value)
    if options.implicitDecimals?
      numvalue /= Math.pow(10, options.implicitDecimals)

    # recommend these rules be last as it changes the primitive type
    if options.deliminate
      # double check we have decimal
      decimalIndex = numvalue.toString().indexOf('.')
      minimumFractionDigits = undefined
      if decimalIndex > 0 # always shows a zero in whole part
        minimumFractionDigits = numvalue.toString().length - decimalIndex - 1
      numvalue = numvalue.toLocaleString('en', minimumFractionDigits: minimumFractionDigits)

    if options.addDollarSign && !(_.isString(numvalue) && numvalue.indexOf('$') >= 0)
      numvalue = "$#{numvalue}"
    return numvalue
