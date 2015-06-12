_ = require 'lodash'
Promise = require "bluebird"
dbs = require '../config/dbs'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
knex = dbs.users.knex

tables =
  mlsNormalization: 'data_normalization_config'

_getRules = (query) ->
  knex.table(tables.mlsNormalization)
  .where query

_createRules = (query, rules) ->
  table = knex.table tables.mlsNormalization
  table.select knex.raw('max(ordering) as count, list')
  .groupBy('list')
  .where data_source_id: query.data_source_id
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
        idx[r.list] = 0
      r.ordering = ++idx[r.list]
  knex.table tables.mlsNormalization
  .insert rules

_putRules = (query, rules) ->
  table = knex.table tables.mlsNormalization
  knex.transaction (trx) ->
    table.transacting trx
    .delete()
    .where query
    .then (result) ->
      _addRules query, rules
    .then (result) ->
      trx.commit()
    .catch (error) ->
      trx.rollback()
      throw new PartiallyHandledError(error)

_deleteRules = (query) ->
  knex.table(tables.mlsNormalization)
  .where query
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
    knex.table tables.mlsNormalization
    .update _.extend(mlsRule, query)
    .where query
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  deleteRule: (mlsId, list, ordering) ->
    _deleteRules data_source_id: mlsId, list: list, ordering: ordering

  knex: knex,
  tables: tables
