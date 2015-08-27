_ = require 'lodash'
Promise = require "bluebird"
logger = require '../config/logger'
dbs = require '../config/dbs'
config = require '../config/config'
{PartiallyHandledError, isUnhandled} = require '../utils/util.partiallyHandledError'
tables = require '../config/tables'
encryptor = require '../config/encryptor'
crudService = require '../utils/crud/util.crud.service.helpers'
jobService = require './service.jobs'
jobQueueTaskDefaults = require '../../common/config/jobQueueTaskDefaults'
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
          # for "schemaReady" to be true, the main_property_data json fields 
          # "db", "table", "field" and "queryTemplate" need to exist and have length > 0
          ret = transaction
          .whereRaw("char_length(cast(main_property_data->>\'db\' as text)) > ?", [0])
          .whereRaw("char_length(cast(main_property_data->>\'table\' as text)) > ?", [0])
          .whereRaw("char_length(cast(main_property_data->>\'field\' as text)) > ?", [0])
          .whereRaw("char_length(cast(main_property_data->>\'queryTemplate\' as text)) > ?", [0])
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

    # once MLS has been saved with no critical errors, create a task & subtasks
    # note: tasks will still be created if new MLS has wrong credentials
    super(entity,id) 
    .then () ->
      # prepare a queue task for this new MLS
      taskObj = _.merge _.clone(jobQueueTaskDefaults.task),
        name: entity.id

      # prepare subtasks for this new MLS  
      subtaskObjs = [
        _.merge _.clone(jobQueueTaskDefaults.subtask_loadDataRawMain),
          task_name: entity.id
          name: "#{entity.id}_loadDataRawMain"
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

      # create stuff
      Promise.all([jobService.tasks.create(taskObj), jobService.subtasks.create(subtaskObjs)])
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)


instance = new MlsConfigCrud(mainDb)
module.exports = instance
