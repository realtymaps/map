_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
dbs = require '../../config/dbs'
sqlHelpers = require '../util.sql.helpers'
require '../../../common/extensions/strings'
tables = require '../../config/tables'
dbs = require '../../config/dbs'
memoize = require 'memoizee'


cached = {}
stateCodeLookup = null


module.exports = (options = {}) ->
  minSimilarity = options.minSimilarity ? 0.4
  if !cached[minSimilarity]
    # prepend the state and county as params for primitive memoizing purposes
    tmp = (stateCodeRaw, countyRaw, value, param) -> Promise.try () ->
      # force correct caps
      county = countyRaw.toInitCaps()
      state = stateCodeRaw.toUpperCase()
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
    # shouldn't change hardly ever, so don't put a maxAge on it -- if we ever need to deal with new values, we
    # can force a refresh by rebooting the servers
    cached[minSimilarity] = memoize.promise(tmp, primitive: true, length: 2)

  # fix the parameter order
  return (param, value) -> Promise.try () ->
    if !value
      throw new DataValidationError('invalid value provided', param, value)
    if !value.stateCode && !value.county
      # pass through a bare fips code...  might be able to just skip the fips validator in rule generation?
      return value
    if !value.stateCode && !value.stateName
      throw new DataValidationError('state info not provided', param, value)
    if !value.county
      throw new DataValidationError('county info not provided', param, value)

    if value.stateCode
      stateCodePromise = Promise.resolve(value.stateCode)
    else
      if !stateCodeLookup  # saving the promise is an effective way to permanently cache the lookup hash
        stateCodeLookup = tables.lookup.usStates()
        .select('code', 'name')
        .then (rows) ->
          lookup = {}
          for row in rows
            lookup[row.name.toInitCaps()] = row.code
          return lookup
      stateCodePromise = stateCodeLookup
      .then (lookup) ->
        return lookup[value.stateName.toInitCaps()] || value.stateName

    stateCodePromise
    .then (stateCode) ->
      cached[minSimilarity](stateCode, value.county, value, param)
