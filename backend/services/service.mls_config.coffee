_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
tables = require '../config/tables'
encryptor = require '../config/encryptor'
crudService = require '../utils/crud/util.crud.service.helpers'
mainDb = tables.config.mls

class MlsConfigCrud extends crudService.ThenableCrud

  getAll: (query = {}, doLogQuery = false) ->
    # schemaReady enacts a filter to return only mls configs with completed main_property_data
    if query?.schemaReady?
      if query.schemaReady == "true"

        # extend our dbFn to account for specialized "where" query on the base dbFn
        transaction = @dbFn()
        tableName = @dbFn.tableName
        @dbFn = () =>
          ret = transaction
          .whereRaw("cast(main_property_data->>\'db\' as text) <> ?", [""])
          .whereRaw("cast(main_property_data->>\'table\' as text) <> ?", [""])
          .whereRaw("cast(main_property_data->>\'field\' as text) <> ?", [""])
          .whereRaw("cast(main_property_data->>\'queryTemplate\' as text) <> ?", [""])
          ret.raw = transaction.raw

          # when this extended dbFn executes, it spits out the extended query but resets itself to the original base listed here
          @dbFn = tables.config.mls
          ret

        @dbFn.tableName = tableName
      delete query.schemaReady
    super(query, doLogQuery)

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
