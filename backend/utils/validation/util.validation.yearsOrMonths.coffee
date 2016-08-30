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
    if !value
      return null
    years = +value.years
    months = +value.months
    if !years && !months
      return null
    if !years
      remainder = months % 12
      if remainder == 0 || (remainder == 6 && months != 6)
        years = months / 12
    if years
      if years == 1
        return "1 year"
      return "#{years} years"
    else if months == 1
      return "1 month"
    else
      return "#{months} months"
