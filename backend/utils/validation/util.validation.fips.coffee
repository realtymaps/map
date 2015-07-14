_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
dbs = require '../../config/dbs'
sqlHelpers = require '../util.sql.helpers'
require '../../../common/extensions/strings'


knex = dbs.users.knex


module.exports = (options = {}) ->
  minSimilarity = options.minSimilarity ? 0.4
  (param, value) -> Promise.try () ->
    if !value || !value.stateCode || !value.county
      throw new DataValidationError("stateCode and county are required", param, value)
    # force correct caps
    county = value.county.toInitCaps()
    state = value.stateCode.toUpperCase()
    knex.select('*', knex.raw("similarity(county, '#{county}') AS similarity"))
    .from('fips_lookup')
    .where(state: state)
    .orderByRaw("similarity(county, '#{county}') DESC")
    .limit(1)
    .then (results) ->
      if results[0].similarity < minSimilarity
        return Promise.reject new DataValidationError("acceptable match not found in #{state}: closest match is #{results[0].county} with similarity #{results[0].similarity}, needed at least #{minSimilarity}", param, value)
      return results[0].code
