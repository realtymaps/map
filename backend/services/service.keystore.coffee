tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
_ = require 'lodash'


_getValuesMap = (table, namespace, options={}) ->
  _getValues(table, namespace, options)
  .then (result) ->
    map = {}
    for kv in result
      map[kv.key] = kv.value
    if options.defaultValues?
      _.extend(map, options.defaultValues)
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

_setValue = (table, key, value, options={}) ->
  query = table(options.transaction)
  .where(key: key)
  if !options.namespace?
    query = query.whereNull('namespace')
  else
    query = query.where(namespace: options.namespace)
  query
  .update(value: sqlHelpers.safeJsonArray(table(), value))
  .returning('*')
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
      result[0].value

  
module.exports =
  userDb:
    getValues: _getValues.bind(null, tables.keystore.userDb)
    getValuesMap: _getValuesMap.bind(null, tables.keystore.userDb)
    getValue: _getValue.bind(null, tables.keystore.userDb)
    setValue: _setValue.bind(null, tables.keystore.userDb)
  propertyDb:
    getValues: _getValues.bind(null, tables.keystore.propertyDb)
    getValuesMap: _getValuesMap.bind(null, tables.keystore.propertyDb)
    getValue: _getValue.bind(null, tables.keystore.propertyDb)
    setValue: _setValue.bind(null, tables.keystore.propertyDb)
