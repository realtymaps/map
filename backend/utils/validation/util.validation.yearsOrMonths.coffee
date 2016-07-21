Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
dbs = require '../../config/dbs'
require '../../../common/extensions/strings'
tables = require '../../config/tables'
dbs = require '../../config/dbs'
memoize = require 'memoizee'
usStates = require '../../../common/utils/util.usStates'


module.exports = (options = {}) ->
  return (param, value) -> Promise.try () ->
    if !value || (!value.years && !value.months)
      throw new DataValidationError('invalid value provided', param, value)
    if value.years
      years = value.years
    else
      remainder = value.months % 12
      if remainder == 0 || (remainder == 6 && value.months != 6)
        years = value.months / 12
    if years
      if years == 1
        return "1 year"
      return "#{value.years} years"
    else if value.months == 1
      return "1 month"
    else
      return "#{value.months} months"
