_ = require 'lodash'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:mls_config')
externalAccounts = require '../services/service.externalAccounts'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
jobService = require './service.jobs'
jobQueueTaskDefaults = require '../../common/config/jobQueueTaskDefaults'

mlsServerFields = ['url', 'username', 'password']

class MlsConfigService extends ServiceCrud

  getAll: (entity = {}) ->
    query = @dbFn()
    # schemaReady enacts a filter to return only mls configs with completed listing_data
    if entity?.schemaReady?
      if entity.schemaReady == 'true'

        # for "schemaReady" to be true, the listing_data json fields
        # "db", "table", and "field" need to exist and have length > 0
        query
        .whereRaw("char_length(cast(listing_data->>\'db\' as text)) > ?", [0])
        .whereRaw("char_length(cast(listing_data->>\'table\' as text)) > ?", [0])
        .whereRaw("char_length(cast(listing_data->>\'field\' as text)) > ?", [0])
      delete entity.schemaReady

    super(entity, query: query)
    .map (mlsConfig) ->
      externalAccounts.getAccountInfo(mlsConfig.id)
      .then (accountInfo) ->
        mlsConfig.url = accountInfo.url
        mlsConfig.username = accountInfo.username
        mlsConfig

  update: (entity) ->
    super(_.omit(entity, mlsServerFields.concat ['ready'])) # 'ready' is a maintenance field from frontend

  updatePropertyData: (id, propertyData) ->
    @update({id: id, listing_data: propertyData})

  # Privileged
  updateServerInfo: (id, serverInfo) ->
    externalAccounts.getAccountInfo(id)
    .then (accountInfo) ->
      update = _.pick(serverInfo, mlsServerFields)
      update.name = id
      update.environment = accountInfo.environment
      externalAccounts.updateAccountInfo(update)
    .then (result) ->
      result == 1
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "Error updating external account for MLS: #{id}")

  # Privileged
  create: (entity) ->
    @logger.debug () -> "create() arguments: entity=#{JSON.stringify(entity)}"
    newMls = _.omit(entity, ['url', 'username', 'password'])
    @logger.debug () -> "create() newMls: #{JSON.stringify(newMls)}"
    newMls.id = entity.id

    # once MLS has been saved with no critical errors, create a task & subtasks
    # note: tasks will still be created if new MLS has wrong credentials
    super(newMls)
    .then () ->
      accountInfo = _.pick(entity, ['url', 'username', 'password'])
      accountInfo.name = newMls.id
      externalAccounts.insertAccountInfo(accountInfo)
    .then () ->
      # prepare a queue task for this new MLS
      taskObj = _.merge _.clone(jobQueueTaskDefaults.task),
        name: newMls.id

      # prepare subtasks for this new MLS
      subtaskObjs = [
        _.merge _.clone(jobQueueTaskDefaults.subtask_loadRawData),
          task_name: newMls.id
          name: "#{newMls.id}_loadRawData"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_normalizeData),
          task_name: newMls.id
          name: "#{newMls.id}_normalizeData"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_recordChangeCounts),
          task_name: newMls.id
          name: "#{newMls.id}_recordChangeCounts"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_finalizeDataPrep),
          task_name: newMls.id
          name: "#{newMls.id}_finalizeDataPrep"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_finalizeData),
          task_name: newMls.id
          name: "#{newMls.id}_finalizeData"
      ,
        _.merge _.clone(jobQueueTaskDefaults.subtask_activateNewData),
          task_name: newMls.id
          name: "#{newMls.id}_activateNewData"
      ]
      Promise.join(jobService.tasks.create(taskObj), jobService.subtasks.create(subtaskObjs), () ->)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error, "Failed to create task/subtasks for new MLS: #{newMls.id}")


instance = new MlsConfigService tables.config.mls
module.exports = instance
