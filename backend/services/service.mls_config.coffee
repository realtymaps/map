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

_encrypt = (record) ->
  if record.password
    record.password = encryptor.encrypt(record.password)
  record

_decrypt = (record) ->
  if record.password
    record.password = encryptor.decrypt(record.password)
  record

module.exports =

  getAll: () ->
    knex.table(tables.mlsConfig)
    .then (data) ->
      _.map(data, _decrypt)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  getById: (id) ->
    knex.table(tables.mlsConfig)
    .where(id: id)
    .then (data) ->
      if data?[0]
        _decrypt data[0]
      else
        false

  update: (id, mlsConfig) ->
    _encrypt mlsConfig
    knex.table(tables.mlsConfig)
    .where(id: id)
    .update(mlsConfig)
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  create: (mlsConfig) ->
    _encrypt mlsConfig
    knex.table(tables.mlsConfig)
    .insert(mlsConfig)
    .then (result) ->
      result.rowCount == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

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
