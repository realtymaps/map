_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
tables = require '../../config/tables'
memoize = require 'memoizee'
require '../../config/promisify'


getLookupMap = (data_source_id, data_list_type, LookupName, param, value) ->
  tables.config.dataSourceLookups()
  .select('LongValue', 'Value')
  .where({data_source_id, data_list_type, LookupName})
  .then (rows) ->
    if !rows?.length
      throw new DataValidationError("lookup '#{LookupName}' not found for source #{data_source_id}, list_type #{data_list_type}", param, value)
    lookup = {}
    for row in rows
      lookup[row.Value] = row.LongValue
    return lookup

getLookupMap = memoize.promise(getLookupMap, {primitive: true, length: 3})


getLookupName = (data_source_id, data_list_type, proxyName, param, value) ->
  tables.config.dataSourceFields()
  .select('LookupName')
  .where({data_source_id, data_list_type, SystemName: proxyName})
  .then (rows) ->
    if !rows?.length
      throw new DataValidationError("lookup proxy '#{proxyName}' not found for source #{data_source_id}, list_type #{data_list_type}", param, value)
    if !rows[0]?.LookupName
      throw new DataValidationError("lookup proxy '#{data_source_id}/#{data_list_type}/#{proxyName}' has no lookup name", param, value)
    return rows[0]?.LookupName

getLookupName = memoize.promise(getLookupName, {primitive: true, length: 3})



doMapping = (param, options, map, singleValue) ->
  mapped = map[singleValue]
  if mapped?
    return mapped
  if typeof(singleValue) == 'string'
    singleValue = singleValue.trim()
    mapped = map[singleValue]
    if mapped?
      return mapped
  if !singleValue? || singleValue == ''
    return null
  if options.unmapped == 'pass'
    return singleValue
  if options.unmapped == 'null'
    return null
  throw new DataValidationError("unmappable value, options are: #{JSON.stringify(_.keys(map))}", param, singleValue)


# Goal is to map the value of the param to a match mapped value
#
# use case:
# sold, pending-sale, off-market all map to not-for-sale
#
# Returns the mapped value.
module.exports = (options = {}) ->
  (param, value) ->
    Promise.try () ->
      if !options.map && (!options.lookup || !options.lookup.dataSourceId || !options.lookup.dataListType)
        throw new DataValidationError("no map or lookup provided, options are: #{JSON.stringify(options)}", param, value)
      if options.map
        return options.map
      else if options.lookup.lookupName
        return getLookupMap(options.lookup.dataSourceId, options.lookup.dataListType, options.lookup.lookupName, param, value)
      else if options.lookup.proxyName
        return getLookupName(options.lookup.dataSourceId, options.lookup.dataListType, options.lookup.proxyName, param, value)
        .then (lookupName) ->
          getLookupMap(options.lookup.dataSourceId, options.lookup.dataListType, lookupName, param, value)
      else
        throw new DataValidationError("no lookup name or proxy name provided, options are: #{JSON.stringify(options)}", param, value)
    .then (map) ->
      if Array.isArray(value)
        return _.map(value, doMapping.bind(null, param, options, map))
      else
        return doMapping(param, options, map, value)
