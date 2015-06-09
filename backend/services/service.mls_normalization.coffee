_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
{PartiallyHandledError, isUnhandled} = require '../utils/util.PartiallyHandledError'

knex = dbs.users.knex

tables =
  mlsNormalization: 'data_normalization_config'

module.exports =

  getRules: (mlsId) ->
    knex.table(tables.mlsNormalization)
    .where
      data_source_id: mlsId
    .then (data) ->
      data?[0]

  createRule: (mlsId, listId, mlsNormalization) ->
    knex.table(table.mlsNormalization)
    .count('* as count')
    .where
      data_source_id: mlsId
      list: listId
    .then (result) ->
        mlsNormalization.id = result[0].count
        knex.table(tables.mlsNormalization)
        .insert(mlsNormalization)
        .then (result) ->
          result.rowCount == 1
        .catch isUnhandled, (error) ->
          throw new PartiallyHandledError(error)

  updateRule: (mlsId, list, ordering, mlsNormalization) ->
    knex.table(tables.mlsNormalization)
    .where
      data_source_id: mlsId,
      list: list,
      ordering: ordering
    .update mlsNormalization
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  deleteRule: (mlsId, list, ordering) ->
    knex.table(tables.mlsNormalization)
    .where
      id: mlsId,
      list: list,
      ordering: ordering
    .delete()
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  knex: knex,
  tables: tables
