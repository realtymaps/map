_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
Encryptor = require '../utils/util.encryptor'

encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)

knex = dbs.users.knex

tables =
  mlsConfig: 'mls_config'

_encrypt = (record) ->
  record.password = encryptor.encrypt(record.password)
  record

_decrypt = (record) ->
  record.password = encryptor.decrypt(record.password)
  record

module.exports =

  getAll: () ->
    knex.table(tables.mlsConfig)
    .then (data) ->
      _map data _decrypt

  getById: (id) ->
    knex.table(tables.mlsConfig)
      .where(id: id)
    .then (data) ->
      _decrypt data?[0]

  update: (id, mlsConfig) ->
    _encrypt mlsConfig
    knex.table(tables.mlsConfig)
      .where(id: id)
      .update(mlsConfig)

  create: (mlsConfig) ->
    _encrypt mlsConfig
    knex.table(tables.mlsConfig)
      .insert(mlsConfig)

  delete: (id) ->
    knex.table(tables.mlsConfig)
      .where(id: id)
      .delete()

  knex: knex,
  tables: tables
