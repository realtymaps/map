_ = require 'lodash'
logger = require('../config/logger').spawn('service.dataSourceRules')
dbs = require '../config/dbs'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
logger = require('../config/logger').spawn('service:dataSourceRules')
uuid = require 'node-uuid'

_getRules = (query) ->
  tables.config.dataNormalization()
  .where query

_createRules = (query, rules) ->
  tables.config.dataNormalization()
  .select(dbs.get('main').raw('max(ordering) as count, list'))
  .groupBy('list')
  .where(query)
  .then (counts) ->
    _addRules query, rules, counts
  .then (result) ->
    result.rowCount == rules.length
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error)

_addRules = (query, rules, counts) ->
  _.each rules, (r) ->
    _.extend r, query
  idx = {}
  _.each counts, (c) ->
    idx[c.list] = c.count
  _.each rules, (r) ->
    if !r.order?
      if !idx[r.list]?
        idx[r.list] = -1
      idx[r.list] = idx[r.list] + 1
      r.ordering = idx[r.list]

  tables.config.dataNormalization()
  .insert(rules)

_putRules = (query, rules) ->
  # This used to be wrapped in a transcation, but it was causing deadlocks so instead there is a 2-stage delete
  del_id = uuid.v1()
  logger.debug -> "PUT #{JSON.stringify query} #{rules.length} rules"
  tables.config.dataNormalization()
  .update(data_source_id: del_id)
  .where(query)
  .then (result) ->
    _addRules(query, rules)
  .catch isUnhandled, (error) ->
    data_source_id = query.data_source_id
    query.data_source_id = del_id
    tables.config.dataNormalization()
    .update(data_source_id: data_source_id)
    .where(query)
    .then ->
      throw new PartiallyHandledError(error)
  .then (result) ->
    tables.config.dataNormalization()
    .delete()
    .where(data_source_id: del_id)

_deleteRules = (query) ->
  tables.config.dataNormalization()
  .where(query)
  .delete()
  .then (result) ->
    result >= 0
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error)

module.exports =

  getRules: (dataSourceId, dataSourceType, dataListType) ->
    _getRules data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType

  createRules: (dataSourceId, dataSourceType, dataListType, rules) ->
    _createRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType}, rules

  putRules: (dataSourceId, dataSourceType, dataListType, rules) ->
    _putRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType}, rules

  deleteRules: (dataSourceId, dataSourceType, dataListType) ->
    _deleteRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType}

  getListRules: (dataSourceId, dataSourceType, dataListType, list) ->
    _getRules data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list

  createListRules: (dataSourceId, dataSourceType, dataListType, list, rules) ->
    _createRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list}, rules

  putListRules: (dataSourceId, dataSourceType, dataListType, list, rules) ->
    _putRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list}, rules

  deleteListRules: (dataSourceId, dataSourceType, dataListType, list) ->
    _deleteRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list}

  getRule: (dataSourceId, dataSourceType, dataListType, list, ordering) ->
    _getRules data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list, ordering: ordering
    .then (result) ->
      result?[0]

  updateRule: (dataSourceId, dataSourceType, dataListType, list, ordering, rule) ->
    query = data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list, ordering: ordering
    tables.config.dataNormalization()
    .update(_.extend(rule, query))
    .where(query)
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  deleteRule: (dataSourceId, dataSourceType, dataListType, list, ordering) ->
    _deleteRules {data_source_id: dataSourceId, data_source_type: dataSourceType, data_type: dataListType, list: list, ordering: ordering}
