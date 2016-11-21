util = require 'util'
_ = require 'lodash'
logger = require('../config/logger').spawn('service:jobs')
tables = require '../config/tables'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
jobQueue = require './service.jobQueue'
dbs = require '../config/dbs'

#
# crud for queue/task/subtask, with added flavor to search substrings among multiple fields
#
class TaskService extends ServiceCrud
  getAll: (entity = {}) ->
    substrFields = {}

    # test for expected values (mapping of field names -> substring would be in entity)
    if entity?.name?
      if entity.name
        substrFields.name = entity.name
      delete entity.name

    if entity?.task_name?
      if entity.task_name
        substrFields.task_name = entity.task_name
      delete entity.task_name

    if not _.isEmpty substrFields
      # extend our dbFn to account for specialized "where" entity on the base dbFn
      old_dbFn = @dbFn
      transaction = @dbFn()
      tableName = @dbFn.tableName

      # build entity for searching given substrings on given fields of @dbFn table
      @dbFn = () =>
        ret = transaction
        fields = Object.keys substrFields
        firstKey = fields.pop()
        whereRawStr = "strpos(#{firstKey}, '#{substrFields[firstKey]}') > 0"
        while fields.length > 0
          nextKey = fields.pop()
          whereRawStr = "#{whereRawStr} or strpos(#{nextKey}, '#{substrFields[nextKey]}') > 0"
        ret = ret.whereRaw(whereRawStr)
        ret.raw = transaction.raw

        # when this extended dbFn executes, it spits out the extended entity but resets itself to the original base listed here
        @dbFn = old_dbFn
        ret
      @dbFn.tableName = tableName
    super(entity)

  create: (entity, id) ->
    if _.isArray entity
      throw new Error 'All objects must already include unique identifiers' unless _.every entity, @idKey
    super(entity, id)

  delete: (id) ->
    super(id)
    .then () =>
      if @dbFn.tableName == 'jq_task_config'
        tables.jobQueue.subtaskConfig().where('task_name', id).delete()


#
# helpers to query task reporting tables
#
jobStatGetters =
  taskHistory: (entity = {}) ->
    dbquery = tables.jobQueue.taskHistory()

    _interval = '30 days'
    if entity.timerange?
      if entity.timerange in ['1 hour', '1 day', '7 days', '30 days', '90 days', 'all']
        _interval = if entity.timerange == 'all' then '120 days' else entity.timerange # account for some sort of upper bound
      delete entity.timerange

    whereInterval = "now_utc() - started <= interval '#{_interval}'"
    dbquery = dbquery.whereRaw(whereInterval)

    if entity.list?
      if entity.list == 'true'
        dbquery = dbquery
        .select(dbs.get('main').raw('DISTINCT ON (name) name'), 'current')
        .groupBy('name', 'current')
        .orderBy('name')
        .orderBy('current', 'DESC')
      delete entity.list

    dbquery.where(entity)

  subtaskErrorHistory: (entity = {}) ->
    dbquery = tables.jobQueue.subtaskErrorHistory()

    _interval = '30 days'
    if entity.timerange?
      if entity.timerange in ['1 hour', '1 day', '7 days', '30 days', '90 days', 'all']
        _interval = if entity.timerange == 'all' then '120 days' else entity.timerange # account for some sort of upper bound
      delete entity.timerange

    whereInterval = "now_utc() - enqueued <= interval '#{_interval}'"
    dbquery = dbquery.whereRaw(whereInterval)

    if entity.task_name == 'All'
      delete entity.task_name

    dbquery.where(entity)

  summary: (entity = {}) ->
    dbquery = tables.jobQueue.summary()
    dbquery.where(entity)

  health: (entity = {}) ->
    _interval = '30 days'
    # validate time range to 30 days if not specified
    if entity.timerange?
      if entity.timerange in ['1 hour', '1 day', '7 days', '30 days']
        _interval = entity.timerange
      delete entity.timerange
    whereInterval = "now_utc() - rm_inserted_time <= interval '#{_interval}'"

    # segregate query parameters for each of the subqueries, if applicable
    _where1 = entity # _.pluck query, [<foo-items>]
    _where2 = {} # _.pluck query, [<bar-items>]

    # query
    db = dbs.get('main')
    db.select('*')
    .from(
      tables.jobQueue.dataLoadHistory().select(
        db.raw('data_source_id as load_id'),
        db.raw('count(*) as load_count'),
        db.raw('COALESCE(SUM(inserted_rows), 0) AS inserted'),
        db.raw('COALESCE(SUM(updated_rows), 0) AS updated'),
        db.raw('COALESCE(SUM(deleted_rows), 0) AS deleted'),
        db.raw('COALESCE(SUM(invalid_rows), 0) AS invalid'),
        db.raw('COALESCE(SUM(unvalidated_rows), 0) AS unvalidated'),
        db.raw('COALESCE(SUM(raw_rows), 0) AS raw'),
        db.raw('COALESCE(SUM(touched_rows), 0) AS touched')
      )
      .groupByRaw('load_id')
      .whereRaw(whereInterval) # account for time range in this subquery
      .where(_where1)
      .as('s1')
    )
    .leftJoin(
      tables.finalized.combined().select(
        db.raw('data_source_id as combined_id'),
        db.raw("SUM(CASE WHEN now() - up_to_date > interval '2 days' THEN 1 ELSE 0 END) AS out_of_date"),
        db.raw('SUM(CASE WHEN geometry IS NULL THEN 1 ELSE 0 END) AS null_geometry'),
        db.raw('SUM(CASE WHEN ungrouped_fields IS NOT NULL THEN 1 ELSE 0 END) AS ungrouped_fields')
      )
      .groupByRaw('combined_id')
      .where(_where2)
      .as('s2'),
    's1.load_id': 's2.combined_id'
    )


module.exports =
  jobStatGetters: jobStatGetters
  queues: new TaskService(tables.jobQueue.queueConfig, {idKeys: 'name', debugNS: "queuesSvc"})
  tasks: new TaskService(tables.jobQueue.taskConfig, {idKeys: 'name', debugNS: "tasksSvc"})
  subtasks: new TaskService(tables.jobQueue.subtaskConfig, {idKeys: 'name', debugNS: "subtasksSvc"})
