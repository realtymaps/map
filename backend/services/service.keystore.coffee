tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'


_getValues = (table, namespace) ->
  table()
  .select('key', 'value')
  .where(namespace: namespace)
  .then (result=[]) ->
    result

_getValue = (table, key, options={}) ->
  query = table()
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

_setValue = (table, key, value, namespace=null) ->
  query = table()
  .where(key: key)
  if !namespace?
    query = query.whereNull('namespace')
  else
    query = query.where(namespace: namespace)
  query
  .update(value: sqlHelpers.safeJsonArray(table(), value))
  .returning('*')
  .then (result) ->
    if !result?.length
      # couldn't find it to update, need to insert
      table()
      .insert
        key: key
        value: sqlHelpers.safeJsonArray(table(), value)
        namespace: namespace
      .then () ->
        undefined
    else
      result[0].value

  
module.exports =
  getUserDbValues: _getValues.bind(null, tables.keystore.userDb)
  getUserDbValue: _getValue.bind(null, tables.keystore.userDb)
  setUserDbValue: _setValue.bind(null, tables.keystore.userDb)
  #TODO: getPropertyDbValues: _getValues.bind(null, tables.keystore.propertyDb)
  #TODO: getPropertyDbValue: _getValue.bind(null, tables.keystore.propertyDb)
  #TODO: setPropertyDbValue: _setValue.bind(null, tables.keystore.propertyDb)
