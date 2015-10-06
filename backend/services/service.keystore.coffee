require '../config/promisify'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
_ = require 'lodash'
Promise = require "bluebird"
memoize = require 'memoizee'
config = require '../config/config'
dbs = require '../config/dbs'


getValuesMap = (namespace, options={}) ->
  getValues(namespace, options)
  .then (result) ->
    map = {}
    for kv in result
      map[kv.key] = kv.value
    if options.defaultValues?
      _.defaults(map, options.defaultValues)
    map

getValues = (namespace, options={}) ->
  tables.config.keystore(options.transaction)
  .select('key', 'value')
  .where(namespace: namespace)
  .then (result=[]) ->
    result

getValue = (key, options={}) ->
  query = tables.config.keystore(options.transaction)
  .select('value')
  .where(key: key)
  if !options.namespace?
    query = query.whereNull('namespace')
  else
    query = query.where(namespace: options.namespace)
  query.then (result) ->
    if !result?.length
      options.defaultValue
    else
      result[0].value

# setValue resolves to the previous value for the namespace/key (or undefined if it didn't exist)
setValue = (key, value, options={}) ->
  if options.transaction?
    _setValueImpl(key, value, options, options.transaction)
  else
    dbs.get('main').transaction _setValueImpl.bind(null, key, value, options)

_setValueImpl = (key, value, options, transaction) ->
  query = tables.config.keystore(options.transaction)
  if !options.namespace?
    query = query.whereNull('namespace')
  else
    query = query.where(namespace: options.namespace)
  query
  .where(key: key)
  .then (result) ->
    if !result?.length
      # couldn't find it to update, need to insert
      tables.config.keystore(options.transaction)
      .insert
        key: key
        value: sqlHelpers.safeJsonArray(value)
        namespace: options.namespace
      .then () ->
        undefined
    else
      # found a result, so update it and return the old value
      query = tables.config.keystore(options.transaction)
      if !options.namespace?
        query = query.whereNull('namespace')
      else
        query = query.where(namespace: options.namespace)
      query
      .where(key: key)
      .update(value: sqlHelpers.safeJsonArray(value))
      .then () ->
        result[0].value  # note this is the old value

# setValuesMap resolves to a map of the previous values for the namespace/keys (with undefined for keys that didn't exist)
setValuesMap = (map, options={}) ->
  handler = (transaction) ->
    resultsPromises = {}
    for key,value of map
      resultsPromises[key] = _setValueImpl(tables.config.keystore, key, value, options, transaction)
    return Promise.props resultsPromises
  if options.transaction?
    handler(options.transaction)
  else
    dbs.get('main').transaction handler

  
module.exports =
  getValues: getValues
  getValuesMap: getValuesMap
  getValue: getValue
  setValue: setValue
  setValuesMap: setValuesMap
  cache:
    getValues: memoize.promise(getValues, maxAge: 10*60*1000)
    getValuesMap: memoize.promise(getValuesMap, maxAge: 10*60*1000)
    getValue: memoize.promise(getValue, maxAge: 10*60*1000)
