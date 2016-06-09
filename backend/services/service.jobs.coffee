_ = require 'lodash'
logger = require('../config/logger').spawn('service:jobs')
tables = require '../config/tables'
crudService = require '../utils/crud/util.crud.service.helpers'
jobQueue = require './service.jobQueue'
dbs = require '../config/dbs'


# makes sure task maintenance and counts are updated whenever we query for task data
class JobService extends crudService.Crud
  getAll: (query = {}, doLogQuery = false) ->
    jobQueue.doMaintenance()
    .then () =>
      return super(query, doLogQuery)

class TaskService extends crudService.Crud
  getAll: (query = {}, doLogQuery = false) ->
    substrFields = {}

    # test for expected values (mapping of field names -> substring would be in query)
    if query?.name?
      if query.name
        substrFields.name = query.name
      delete query.name

    if query?.task_name?
      if query.task_name
        substrFields.task_name = query.task_name
      delete query.task_name

    if not _.isEmpty substrFields
      # extend our dbFn to account for specialized "where" query on the base dbFn
      old_dbFn = @dbFn
      transaction = @dbFn()
      tableName = @dbFn.tableName

      # build query for searching given substrings on given fields of @dbFn table
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

        # when this extended dbFn executes, it spits out the extended query but resets itself to the original base listed here
        @dbFn = old_dbFn
        ret
      @dbFn.tableName = tableName
    super(query, doLogQuery)

  create: (entity, id, doLogQuery = false) ->
    if _.isArray entity
      throw new Error 'All objects must already include unique identifiers' unless _.every entity, @idKey
    super(entity, id, doLogQuery)

  delete: (id, doLogQuery = false) ->
    super(id, doLogQuery)
    .then () =>
      if @dbFn.tableName == 'jq_task_config'
        tables.jobQueue.subtaskConfig().where('task_name', id).delete()


# provide a contrived "query" that meets requirements for our Crud object
# the structure below facilitates a "where" adaptor to suit this subquery structure
healthDbFn = () ->
  _queryFn = (query = {}) ->
    _interval = '30 days'
    # validate time range to 30 days if not specified
    if query.timerange?
      if query.timerange in ['1 hour', '1 day', '7 days', '30 days']
        _interval = query.timerange
      delete query.timerange
    whereInterval = "now_utc() - rm_inserted_time <= interval '#{_interval}'"

    # segregate query parameters for each of the subqueries, if applicable
    _query1 = query # _.pluck query, [<foo-items>]
    _query2 = {} # _.pluck query, [<bar-items>]

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
      .where(_query1)
      .as('s1')
    )
    .leftJoin(
      tables.finalized.combined().select(
        db.raw('data_source_id as combined_id'),
        db.raw('SUM(CASE WHEN active = true THEN 1 ELSE 0 END) AS active_count'),
        db.raw('SUM(CASE WHEN active = false THEN 1 ELSE 0 END) AS inactive_count'),
        db.raw("SUM(CASE WHEN now() - up_to_date > interval '2 days' THEN 1 ELSE 0 END) AS out_of_date"),
        db.raw('SUM(CASE WHEN geometry IS NULL THEN 1 ELSE 0 END) AS null_geometry'),
        db.raw('SUM(CASE WHEN ungrouped_fields IS NOT NULL THEN 1 ELSE 0 END) AS ungrouped_fields')
      )
      .groupByRaw('combined_id')
      .where(_query2)
      .as('s2'),
    's1.load_id': 's2.combined_id'
    )

  # "where" adaptor call for the above
  _queryFn.where = (query = {}) ->
    return _queryFn(query)

  return _queryFn

historyDbFn = () ->
  _queryFn = (query = {}) ->
    dbquery = tables.jobQueue.taskHistory()

    _interval = '30 days'
    if query.timerange?
      if query.timerange in ['1 hour', '1 day', '7 days', '30 days', '90 days', 'all']
        _interval = if query.timerange == 'all' then '120 days' else query.timerange # account for some sort of upper bound
      delete query.timerange

    whereInterval = "now_utc() - started <= interval '#{_interval}'"
    dbquery = dbquery.whereRaw(whereInterval)

    if query.list?
      if query.list == 'true'
        dbquery = dbquery
        .select(dbs.get('main').raw('DISTINCT ON (name) name'), 'current')
        .groupBy('name', 'current')
        .orderBy('name')
        .orderBy('current', 'DESC')
      delete query.list

    dbquery.where(query)

  # "where" adaptor call for the above
  _queryFn.where = (query = {}) ->
    return _queryFn(query)

  return _queryFn

errorHistoryDbFn = () ->
  _queryFn = (query = {}) ->
    dbquery = tables.jobQueue.subtaskErrorHistory()

    _interval = '30 days'
    if query.timerange?
      if query.timerange in ['1 hour', '1 day', '7 days', '30 days', '90 days', 'all']
        _interval = if query.timerange == 'all' then '120 days' else query.timerange # account for some sort of upper bound
      delete query.timerange

    whereInterval = "now_utc() - enqueued <= interval '#{_interval}'"
    dbquery = dbquery.whereRaw(whereInterval)

    if query.task_name == 'All'
      delete query.task_name

    dbquery.where(query)

  # "where" adaptor call for the above
  _queryFn.where = (query = {}) ->
    return _queryFn(query)

  return _queryFn

module.exports =
  taskHistory: new JobService(historyDbFn, 'name')
  subtaskErrorHistory: new JobService(errorHistoryDbFn, 'id')
  queues: new TaskService(tables.jobQueue.queueConfig, 'name')
  tasks: new TaskService(tables.jobQueue.taskConfig, 'name')
  subtasks: new TaskService(tables.jobQueue.subtaskConfig, 'name')
  summary: new JobService(tables.jobQueue.summary)
  health: crudService.crud(healthDbFn)
