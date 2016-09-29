Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
dbs = require '../../config/dbs'
require '../../../common/extensions/strings'
tables = require '../../config/tables'
memoize = require 'memoizee'
usStates = require '../../../common/utils/util.usStates'


cached = {}


module.exports = (options = {}) ->
  minSimilarity = options.minSimilarity ? 0.4
  if !cached[minSimilarity]
    # prepend the state and county as params for primitive memoizing purposes
    tmp = (stateCode, county, value, param) -> Promise.try () ->
      tables.lookup.fipsCodes()
      .select('*', dbs.get('main').raw("similarity(county, '#{county}') AS similarity"))
      .where(state: stateCode)
      .orderByRaw("similarity(county, '#{county}') DESC")
      .limit(1)
      .then (results) ->
        if !results?[0]?
          return Promise.reject new DataValidationError('no matches found', param, value)
        if results[0].similarity < minSimilarity
          return Promise.reject new DataValidationError("acceptable county match not found: closest match is #{results[0].county}, #{results[0].state} with similarity #{results[0].similarity}, needed at least #{minSimilarity}", param, value)
        return results[0].code
    # shouldn't change hardly ever, so don't put a maxAge on it -- if we ever need to deal with new values, we
    # can force a refresh by rebooting the servers
    cached[minSimilarity] = memoize.promise(tmp, primitive: true, length: 2)

  # fix the parameter order
  return (param, value) -> Promise.try () ->
    if !value
      throw new DataValidationError('invalid value provided', param, value)
    if value.fipsCode
      return value.fipsCode
    if !value.stateCode
      throw new DataValidationError('state info not provided', param, value)
    if !value.county
      throw new DataValidationError('county info not provided', param, value)

    Promise.try () ->
      if value.stateCode.length == 2
        return value.stateCode.toUpperCase()
      else
        stateCode = usStates.getByName(value.stateCode)?.code
        if !stateCode
          throw new DataValidationError('could not look up state code', param, value)
        return stateCode
    .then (stateCode) ->
      cached[minSimilarity](stateCode, value.county.toInitCaps(), value, param)
