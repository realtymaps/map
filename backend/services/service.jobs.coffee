_ = require 'lodash'
{jobQueue} = require '../config/tables'
crudService = require '../utils/crud/util.crud.service.helpers'

_summary = crudService.crud(jobQueue.jqSummary)


_health = crudService.crud(jobQueue.dataHealth)

class JobService extends crudService.Crud
  getAll: (query = {}, doLogQuery = false) ->
    console.log "extended getAll, JobCrud"
    super(query, doLogQuery)

_summary2 = JobService(jobQueue.jqSummary)

console.log "#### _summary:"
console.log _summary
console.log "#### _summary2:"
console.log _summary2

module.exports =
  taskHistory: crudService.crud(jobQueue.taskHistory, 'name')
  queues: crudService.crud(jobQueue.queueConfig, 'name')
  tasks: crudService.crud(jobQueue.taskConfig, 'name')
  subtasks: crudService.crud(jobQueue.subtaskConfig, 'name')
  # summary: JobService(jobQueue.jqSummary)
  # health: JobService(jobQueue.dataHealth)
  summary: _summary
  health: _health