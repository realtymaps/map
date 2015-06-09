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
      data

  createRule: (mlsId, list, mlsNormalization) ->
    mlsNormalization.data_source_id = mlsId
    mlsNormalization.list = list

    knex.table(tables.mlsNormalization)
    .count('* as count')
    .where
      data_source_id: mlsId
      list: list
    .then (result) ->
        mlsNormalization.ordering = result[0].count
        knex.table(tables.mlsNormalization)
        .insert(mlsNormalization)
        .then (result) ->
          result.rowCount == 1
        .catch isUnhandled, (error) ->
          throw new PartiallyHandledError(error)

  updateRule: (mlsId, list, ordering, mlsNormalization) ->
    mlsNormalization.data_source_id = mlsId
    mlsNormalization.list = list
    mlsNormalization.ordering = ordering

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
      data_source_id: mlsId,
      list: list,
      ordering: ordering
    .delete()
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  knex: knex,
  tables: tables
