_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
tables = require '../config/tables'
encryptor = require '../config/encryptor'
{ThenableCrud} = require '../utils/crud/util.crud.service.helpers'
mainDb = tables.config.mls

class MlsConfigCrud extends ThenableCrud
  update: (id, entity) ->
    # as config options are added to the mls_config table, they need to be added here as well
    super(id, entity, ['name', 'notes', 'active', 'main_property_data'])

  updatePropertyData: (id, propertyData) ->
    @update(id, {main_property_data: propertyData})

  # Privileged
  updateServerInfo: (id, serverInfo) ->
    if serverInfo.password
      serverInfo.password = encryptor.encrypt(serverInfo.password)
    @base('getById', id)
    .update _.pick(serverInfo, ['url', 'username', 'password'])
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  create: (entity, id) ->
    entity.id = id
    if entity.password
      entity.password = encryptor.encrypt(entity.password)
    super(entity,id)

instance = new MlsConfigCrud(mainDb)
module.exports = instance
