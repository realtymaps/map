_ = require 'lodash'
Promise = require "bluebird"
dbs = require '../config/dbs'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
knex = dbs.users.knex
tables = require '../config/tables'


_getRules = (query) ->
  tables.config.dataNormalization()
  .where query

_createRules = (query, rules) ->
  tables.config.dataNormalization()
  .select(knex.raw('max(ordering) as count, list'))
  .groupBy('list')
  .where(data_source_id: query.data_source_id)
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
      r.ordering = ++idx[r.list]
  tables.config.dataNormalization()
  .insert(rules)

_putRules = (query, rules) ->
  knex.transaction (trx) ->
    tables.config.dataNormalization(trx)
    .delete()
    .where(query)
    .then (result) ->
      _addRules(query, rules)
    .then (result) ->
      trx.commit()
    .catch (error) ->
      trx.rollback()
      throw new PartiallyHandledError(error)

_deleteRules = (query) ->
  tables.config.dataNormalization()
  .where(query)
  .delete()
  .then (result) ->
    result >= 0
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error)

module.exports =

  getRules: (mlsId) ->
    _getRules data_source_id: mlsId

  createRules: (mlsId, rules) ->
    _createRules data_source_id: mlsId, rules

  putRules: (mlsId, rules) ->
    _putRules data_source_id: mlsId, rules

  deleteRules: (mlsId) ->
    _deleteRules data_source_id: mlsId

  getListRules: (mlsId, list) ->
    _getRules data_source_id: mlsId, list: list

  createListRules: (mlsId, list, rules) ->
    _createRules data_source_id: mlsId, list: list, rules

  putListRules: (mlsId, list, rules) ->
    _putRules data_source_id: mlsId, list: list, rules

  deleteListRules: (mlsId, list) ->
    _deleteRules data_source_id: mlsId, list: list

  getRule: (mlsId, list, ordering) ->
    _getRules data_source_id: mlsId, list: list, ordering: ordering
    .then (result) ->
      result?[0]

  updateRule: (mlsId, list, ordering, mlsRule) ->
    query = data_source_id: mlsId, list: list, ordering: ordering
    tables.config.dataNormalization()
    .update(_.extend(mlsRule, query))
    .where(query)
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  deleteRule: (mlsId, list, ordering) ->
    _deleteRules data_source_id: mlsId, list: list, ordering: ordering
