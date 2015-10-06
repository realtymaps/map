_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require './util.error.dataValidation'
dbs = require '../../config/dbs'
sqlHelpers = require '../util.sql.helpers'
require '../../../common/extensions/strings'
tables = require '../../config/tables'
dbs = require '../../config/dbs'
memoize = require 'memoizee'


cached = {}


module.exports = (options = {}) ->
  minSimilarity = options.minSimilarity ? 0.4
  if !cached[minSimilarity]
    # reverse the parameter order, because we want to ignore param
    tmp = (value, param) -> Promise.try () ->
      if !value || (!value.stateCode and value.county) || (value.stateCode and !value.county)
        throw new DataValidationError('invalid value provided', param, value)
      # force correct caps
      if value.stateCode && value.county
        county = value.county.toInitCaps()
        state = value.stateCode.toUpperCase()
        tables.lookup.fipsCodes()
        .select('*', dbs.get('main').raw("similarity(county, '#{county}') AS similarity"))
        .where(state: state)
        .orderByRaw("similarity(county, '#{county}') DESC")
        .limit(1)
        .then (results) ->
          if !results?[0]?
            return Promise.reject new DataValidationError('no matches found', param, value)
          if results[0].similarity < minSimilarity
            return Promise.reject new DataValidationError("acceptable county match not found: closest match is #{results[0].county}, #{results[0].state} with similarity #{results[0].similarity}, needed at least #{minSimilarity}", param, value)
          return results[0].code
      else
        return value
    # shouldn't change hardly ever, so don't put a maxAge on it -- if we ever need to deal with new values, we
    # can force a refresh by rebooting the servers
    cached[minSimilarity] = memoize.promise(tmp, primitive: true, length: 1)
  
  # fix the parameter order
  return (param, value) -> cached[minSimilarity](value, param)
