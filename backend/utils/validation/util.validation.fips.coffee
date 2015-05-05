Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
dbs = require '../../config/dbs'
sqlHelpers = require '../util.sql.helpers'


knex = dbs.users.knex


module.exports = (options = {}) ->
  minSimilarity = options.minSimilarity ? 0.4
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null
    query = knex.select('*', knex.raw("similarity(county, '#{value}') AS similarity")).from('fips_lookup')
    if options.states?.length
      sqlHelpers.whereIn(query, 'state', options.states)
    query
    .orderByRaw("similarity(county, '#{value}') DESC")
    .limit(1)
    .then (results) ->
      if results[0].similarity < minSimilarity
        return Promise.reject new DataValidationError("acceptable match not found in #{JSON.stringify(options.states)}: closest match is #{results[0].county}, #{results[0].state} with similarity #{results[0].similarity}, needed at least #{minSimilarity}", param, value)
      return results[0].code
