_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
tables = require '../../config/tables'
memoize = require 'memoizee'
require '../../config/promisify'


getLookupMap = (data_source_id, data_list_type, LookupName) ->
  query = tables.config.dataSourceLookups()
  .select('LongValue', 'Value')
  .where({data_source_id, data_list_type, LookupName})
  .then (rows) ->
    if !rows?.length
      throw new DataValidationError("no map provided, options are: #{JSON.stringify(options)}", param, value)
    lookup = {}
    for row in rows
      lookup[row.Value] = row.LongValue
    return lookup
getLookupMap = memoize.promise(getLookupMap, {primitive: true})

# Goal is to map the value of the param to a match mapped value
#
# TODO: rename to mapValues
# use case:
# sold, pending-sale, off-market all map to not-for-sale
#
# Returns the mapped value.
module.exports = (options = {}) ->
  (param, value) ->
    Promise.try () ->
      if !options.map && (!options.lookup || !options.lookup.dataSourceId || !options.lookup.dataListType || !options.lookup.lookupName)
        throw new DataValidationError("no map or lookup provided, options are: #{JSON.stringify(options)}", param, value)
      if options.map
        return options.map
      else
        return getLookupMap(options.lookup.dataSourceId, options.lookup.dataListType, options.lookup.lookupName)
    .then (map) ->
      mapped = map[value]
      if mapped?
        return mapped
      if !value? || value == ''
        return null
      if options.passUnmapped
        return value
      throw new DataValidationError("unmappable value, options are: #{JSON.stringify(_.keys(map))}", param, value)
