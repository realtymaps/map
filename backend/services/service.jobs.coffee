_ = require 'lodash'
Promise = require 'bluebird'
tables = require '../config/tables'
crudService = require '../utils/crud/util.crud.service.helpers'
jobQueue = require '../utils/util.jobQueue'

# makes sure task maintenance and counts are updated whenever we query for task data
class JobService extends crudService.Crud
  getAll: (query = {}, doLogQuery = false) ->
    jobQueue.doMaintenance()
    .then () =>
      return super(query, doLogQuery)

_summary = new JobService(tables.jobQueue.jqSummary)
_taskHistory = new JobService(tables.jobQueue.taskHistory, 'name')


module.exports =
  taskHistory: _taskHistory
  queues: crudService.crud(tables.jobQueue.queueConfig, 'name')
  tasks: crudService.crud(tables.jobQueue.taskConfig, 'name')
  subtasks: crudService.crud(tables.jobQueue.subtaskConfig, 'name')
  summary: _summary
  health: crudService.crud(tables.jobQueue.dataHealth)