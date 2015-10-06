require '../config/promisify'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
_ = require 'lodash'
Promise = require "bluebird"
memoize = require 'memoizee'
config = require '../config/config'
dbs = require '../config/dbs'


_getValuesMap = (namespace, defaultValues, transaction) ->
  _getValues(namespace, transaction)
  .then (result) ->
    map = {}
    for kv in result
      map[kv.key] = kv.value
    if defaultValues?
      _.defaults(map, defaultValues)
    map

_getValues = (namespace, transaction) ->
  tables.config.keystore(transaction)
  .select('key', 'value')
  .where(namespace: namespace)
  .then (result=[]) ->
    result

_getValue = (key, namespace, defaultValue, transaction) ->
  query = tables.config.keystore(transaction)
  .select('value')
  .where(key: key)
  if !namespace?
    query = query.whereNull('namespace')
  else
    query = query.where(namespace: namespace)
  query.then (result) ->
    if !result?.length
      defaultValue
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


_cached = {}
_cached.getValue = memoize.promise(_getValue, length: 3, primitive: true, maxAge: 10*60*1000, preFetch: .1)
_cached.getValues = memoize.promise(_getValues, length: 1, primitive: true, maxAge: 10*60*1000, preFetch: .1)
_cached.getValuesMap = memoize.promise(_getValuesMap, length: 2, primitive: true, maxAge: 10*60*1000, preFetch: .1)


module.exports =
  getValue: (key, options={}) -> _getValue(key, options.namespace, options.defaultValue, options.transaction)
  getValues: (namespace, options={}) -> _getValues(namespace, options.transaction)
  getValuesMap: (namespace, options={}) -> _getValuesMap(namespace, options.defaultValues, options.transaction)
  setValue: setValue
  setValuesMap: setValuesMap
  cache:
    getValue: (key, options={}) -> _cached.getValue(key, options.namespace, options.defaultValue)
    getValues: (namespace, options={}) -> _cached.getValues(namespace)
    getValuesMap: (namespace, options={}) -> _cached.getValuesMap(namespace, options.defaultValues)
