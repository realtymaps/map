_ = require 'lodash'
Promise = require 'bluebird'
logger = require '../config/logger'
externalAccounts = require '../services/service.externalAccounts'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
crudService = require '../utils/crud/util.crud.service.helpers'
jobService = require './service.jobs'
jobQueueTaskDefaults = require '../../common/config/jobQueueTaskDefaults'


class MlsConfigCrud extends crudService.ThenableCrud

  getAll: (query = {}, doLogQuery = false) ->
    # schemaReady enacts a filter to return only mls configs with completed listing_data
    if query?.schemaReady?
      if query.schemaReady == 'true'

        # extend our dbFn to account for specialized "where" query on the base dbFn
        transaction = @dbFn()
        tableName = @dbFn.tableName
        @dbFn = () =>
          # for "schemaReady" to be true, the listing_data json fields
          # "db", "table", "field" and "queryTemplate" need to exist and have length > 0
          ret = transaction
          .whereRaw("char_length(cast(listing_data->>\'db\' as text)) > ?", [0])
          .whereRaw("char_length(cast(listing_data->>\'table\' as text)) > ?", [0])
          .whereRaw("char_length(cast(listing_data->>\'field\' as text)) > ?", [0])
          .whereRaw("char_length(cast(listing_data->>\'queryTemplate\' as text)) > ?", [0])
          ret.raw = transaction.raw

          # when this extended dbFn executes, it spits out the extended query but resets itself to the original base listed here
          @dbFn = tables.config.mls
          ret

        @dbFn.tableName = tableName
      delete query.schemaReady
    super(query, doLogQuery)
    .map (mlsConfig) ->
      externalAccounts.getAccountInfo(mlsConfig.id)
      .then (accountInfo) ->
        mlsConfig.url = accountInfo.url
        mlsConfig.username = accountInfo.username
        mlsConfig

  update: (id, entity) ->
    # as config options are added to the mls_config table, they need to be added here as well
    super(id, entity, ['name', 'notes', 'active', 'listing_data', 'data_rules', 'static_ip'])

  updatePropertyData: (id, propertyData) ->
    @update(id, {listing_data: propertyData})

  # Privileged
  updateServerInfo: (id, serverInfo) ->
    externalAccounts.getAccountInfo(id)
    .then (accountInfo) ->
      update = _.pick(serverInfo, ['url', 'username', 'password'])
      update.name = id
      update.environment = accountInfo.environment
      externalAccounts.updateAccountInfo(update)
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error)

  # Privileged
  create: (entity, id) ->
    entity = _.omit(entity, ['url', 'username', 'password'])
    entity.id = id

    # once MLS has been saved with no critical errors, create a task & subtasks
    # note: tasks will still be created if new MLS has wrong credentials
    super(entity,id)
    .then () ->
      accountInfo = _.pick(entity, ['url', 'username', 'password'])
      accountInfo.name = id
      externalAccounts.insertAccountInfo(accountInfo)
    .then () ->
      # prepare a queue task for this new MLS
      taskObj = _.merge _.clone(jobQueueTaskDefaults.task),
        name: entity.id

      # prepare subtasks for this new MLS
      subtaskObjs = [
        _.merge _.clone(jobQueueTaskDefaults.subtask_loadRawData),
          task_name: entity.id
          name: "#{entity.id}_loadRawData"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_normalizeData),
          task_name: entity.id
          name: "#{entity.id}_normalizeData"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_recordChangeCounts),
          task_name: entity.id
          name: "#{entity.id}_recordChangeCounts"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_finalizeDataPrep),
          task_name: entity.id
          name: "#{entity.id}_finalizeDataPrep"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_finalizeData),
          task_name: entity.id
          name: "#{entity.id}_finalizeData"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_activateNewData),
          task_name: entity.id
          name: "#{entity.id}_activateNewData"
      ]
      Promise.join(jobService.tasks.create(taskObj), jobService.subtasks.create(subtaskObjs), () ->)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error, "Failed to create task/subtasks for new MLS: #{entity.id}")


instance = new MlsConfigCrud(tables.config.mls)
module.exports = instance
