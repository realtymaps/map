_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
Encryptor = require '../utils/util.encryptor'
{PartiallyHandledError, isUnhandled} = require '../utils/util.PartiallyHandledError'

encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)

knex = dbs.users.knex

tables =
  mlsConfig: 'mls_config'

module.exports =

  getAll: () ->
    knex.table(tables.mlsConfig)
    .then (data) ->
      data
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  getById: (id) ->
    knex.table(tables.mlsConfig)
    .where(id: id)
    .then (data) ->
      data?[0]

  update: (id, mlsConfig) ->
    knex.table(tables.mlsConfig)
    .where(id: id)
    .update _.pick(mlsConfig, ['name', 'notes', 'active', 'main_property_data'])
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  updatePropertyData: (id, propertyData) ->
    knex.table(tables.mlsConfig)
    .where(id: id)
    .update
      main_property_data: JSON.stringify(propertyData)
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  updateServerInfo: (id, serverInfo) ->
    if serverInfo.password
      encryptor.encrypt(serverInfo.password)
    knex.table(tables.mlsConfig)
    .where(id: id)
    .update _.pick(serverInfo, ['url', 'username', 'password'])
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  create: (mlsConfig) ->
    if mlsConfig.password
      mlsConfig.password = encryptor.encrypt(mlsConfig.password)
    knex.table(tables.mlsConfig)
    .insert(mlsConfig)
    .then (result) ->
      result.rowCount == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  delete: (id) ->
    knex.table(tables.mlsConfig)
    .where(id: id)
    .delete()
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  knex: knex,
  tables: tables
