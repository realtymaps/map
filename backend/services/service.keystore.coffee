tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
_ = require 'lodash'
Promise = require "bluebird"


_getValuesMap = (table, namespace, options={}) ->
  _getValues(table, namespace, options)
  .then (result) ->
    map = {}
    for kv in result
      map[kv.key] = kv.value
    if options.defaultValues?
      _.defaults(map, options.defaultValues)
    map

_getValues = (table, namespace, options={}) ->
  table(options.transaction)
  .select('key', 'value')
  .where(namespace: namespace)
  .then (result=[]) ->
    result

_getValue = (table, key, options={}) ->
  query = table(options.transaction)
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

# _setValue resolves to the previous value for the namespace/key (or undefined if it didn't exist)
_setValue = (table, key, value, options={}) ->
  if options.transaction?
    _setValueImpl(table, key, value, options, options.transaction)
  else
    table.transaction _setValueImpl.bind(null, table, key, value, options)

_setValueImpl = (table, key, value, options, transaction) ->
  query = table(options.transaction)
  if !options.namespace?
    query = query.whereNull('namespace')
  else
    query = query.where(namespace: options.namespace)
  query
  .where(key: key)
  .then (result) ->
    if !result?.length
      # couldn't find it to update, need to insert
      table(options.transaction)
      .insert
        key: key
        value: sqlHelpers.safeJsonArray(table(options.transaction), value)
        namespace: options.namespace
      .then () ->
        undefined
    else
      # found a result, so update it and return the old value
      query = table(options.transaction)
      if !options.namespace?
        query = query.whereNull('namespace')
      else
        query = query.where(namespace: options.namespace)
      query
      .where(key: key)
      .update(value: sqlHelpers.safeJsonArray(table(), value))
      .then () ->
        result[0].value  # note this is the old value

# _setValuesMap resolves to a map of the previous values for the namespace/keys (with undefined for keys that didn't exist)
_setValuesMap = (table, map, options={}) ->
  handler =  (transaction) ->
    resultsPromises = {}
    for key,value of map
      resultsPromises[key] = _setValueImpl(table, key, value, options, transaction)
    return Promise.props resultsPromises
  if options.transaction?
    handler(options.transaction)
  else
    table.transaction handler

  
module.exports =
  userDb:
    getValues: _getValues.bind(null, tables.keystore.userDb)
    getValuesMap: _getValuesMap.bind(null, tables.keystore.userDb)
    getValue: _getValue.bind(null, tables.keystore.userDb)
    setValue: _setValue.bind(null, tables.keystore.userDb)
    setValuesMap: _setValuesMap.bind(null, tables.keystore.userDb)
  propertyDb:
    getValues: _getValues.bind(null, tables.keystore.propertyDb)
    getValuesMap: _getValuesMap.bind(null, tables.keystore.propertyDb)
    getValue: _getValue.bind(null, tables.keystore.propertyDb)
    setValue: _setValue.bind(null, tables.keystore.propertyDb)
    setValuesMap: _setValuesMap.bind(null, tables.keystore.propertyDb)
