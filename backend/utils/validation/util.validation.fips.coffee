_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
dbs = require '../../config/dbs'
sqlHelpers = require '../util.sql.helpers'
require '../../../common/extensions/strings'


knex = dbs.users.knex


module.exports = (options = {}) ->
  minSimilarity = options.minSimilarity ? 0.4
  if options.state?
    states = [options.state.toUpperCase()]
  else if options.states?.length
    states = _.map(options.states, (state) -> state.toUpperCase())
  (param, value) -> Promise.try () ->
    if !value
      return null
    # force init caps
    value = value.toInitCaps()
    query = knex.select('*', knex.raw("similarity(county, '#{value}') AS similarity")).from('fips_lookup')
    if states?
      sqlHelpers.whereIn(query, 'state', states)
    query
    .orderByRaw("similarity(county, '#{value}') DESC")
    .limit(1)
    .then (results) ->
      if results[0].similarity < minSimilarity
        return Promise.reject new DataValidationError("acceptable match not found in #{JSON.stringify(states)}: closest match is #{results[0].county}, #{results[0].state} with similarity #{results[0].similarity}, needed at least #{minSimilarity}", param, value)
      return results[0].code
