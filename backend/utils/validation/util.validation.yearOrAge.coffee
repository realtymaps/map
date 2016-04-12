_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
dbs = require '../../config/dbs'
sqlHelpers = require '../util.sql.helpers'
require '../../../common/extensions/strings'
tables = require '../../config/tables'
dbs = require '../../config/dbs'
memoize = require 'memoizee'
stateCodeLookup = require '../util.stateCodeLookup'


cached = {}


module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value.year
      return {label: 'Year Built', value: value.year}
    else if value.age
      return {label: 'Age', value: value.age}
    else
      return null
