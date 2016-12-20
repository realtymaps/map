_ = require 'lodash'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('service:mls_config')
# coffeelint: enable=check_scope
externalAccounts = require '../services/service.externalAccounts'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
memoize = require 'memoizee'
sqlHelpers = require '../utils/util.sql.helpers'

mlsServerFields = ['url', 'username', 'password']


class MlsConfigService extends ServiceCrud

  constructor: (args...) ->
    super(args...)
    getByIdCachedImpl = (entity, opts) =>
      @getById(entity, opts)
      .then (mlsConfig) ->
        if !mlsConfig?.length
          return null
        return mlsConfig[0]
    @getByIdCached = memoize(getByIdCachedImpl, primitive: true, length: 1, maxAge: 60*60*1000)  # cached for 1 hour

  getAll: (entity = {}) ->
    query = @dbFn()
    # schemaReady enacts a filter to return only mls configs with completed listing_data
    if entity?.schemaReady?
      if entity.schemaReady == 'true'

        # for "schemaReady" to be true, the listing_data json fields
        # "db", "table", and "lastModTime" need to exist and have length > 0
        # if mlsListingId is going to be considered a requirement prior to normalization then it needs to be here
        query
        .whereRaw("char_length(cast(listing_data->>\'db\' as text)) > ?", [0])
        .whereRaw("char_length(cast(listing_data->>\'table\' as text)) > ?", [0])
        .whereRaw("char_length(cast(listing_data->>\'lastModTime\' as text)) > ?", [0])
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
    tables.config.mls.transaction (transaction) ->
      tables.config.mls({transaction})
      .insert(newMls)
      .then () ->
        accountInfo = _.pick(entity, ['url', 'username', 'password'])
        accountInfo.name = newMls.id
        externalAccounts.insertAccountInfo(accountInfo, {transaction})
      .then () ->
        # prepare tasks for this new MLS
        tables.jobQueue.taskConfig({transaction})
        .where('name', 'LIKE', '<mlsid>_%')
      .then (taskTemplates) ->
        taskTemplatesJson = JSON.stringify(taskTemplates)
        tasks = JSON.parse(taskTemplatesJson.replace(/<mlsid>/g, newMls.id))
        for task in tasks
          task.blocked_by_tasks = sqlHelpers.safeJsonArray(task.blocked_by_tasks)
          task.blocked_by_locks = sqlHelpers.safeJsonArray(task.blocked_by_locks)
        tables.jobQueue.taskConfig({transaction})
        .insert(tasks)
      .then () ->
        # prepare subtasks for this new MLS
        tables.jobQueue.subtaskConfig({transaction})
        .where('task_name', 'LIKE', '<mlsid>_%')
      .then (subtaskTemplates) ->
        subtaskTemplatesJson = JSON.stringify(subtaskTemplates)
        subtasks = JSON.parse(subtaskTemplatesJson.replace(/<mlsid>/g, newMls.id))
        tables.jobQueue.taskConfig({transaction})
        .insert(subtasks)

    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "Failed to create task/subtasks for new MLS: #{newMls.id}")

  getByIdCached: null  # this is to make it show up in the prototype chain; see constructor for implementation


instance = new MlsConfigService tables.config.mls
module.exports = instance
