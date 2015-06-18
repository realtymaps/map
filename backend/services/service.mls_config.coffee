_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
Encryptor = require '../utils/util.encryptor'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
tables = require '../config/tables'

encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)


module.exports =

  getAll: () ->
    tables.config.mls()
    .then (data) ->
      data
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  getById: (id) ->
    logger.info "#### mls_config service: getById"
# <<<<<<< HEAD
#     logger.info "#### mls_config service: getById"
#     knex.table(tables.mlsConfig)
# =======
    tables.config.mls()
# >>>>>>> origin/master
    .where(id: id)
    .then (data) ->
      data?[0]

  update: (id, mlsConfig) ->
    tables.config.mls()
    .where(id: id)
    .update _.pick(mlsConfig, ['name', 'notes', 'active', 'main_property_data'])
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  updatePropertyData: (id, propertyData) ->
    tables.config.mls()
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
      serverInfo.password = encryptor.encrypt(serverInfo.password)
    tables.config.mls()
    .where(id: id)
    .update _.pick(serverInfo, ['url', 'username', 'password'])
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  create: (mlsConfig, id) ->
    if id
      mlsConfig.id = id
    if mlsConfig.password
      mlsConfig.password = encryptor.encrypt(mlsConfig.password)
    tables.config.mls()
    .insert(mlsConfig)
    .then (result) ->
      result.rowCount == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  delete: (id) ->
    tables.config.mls()
    .where(id: id)
    .delete()
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)
