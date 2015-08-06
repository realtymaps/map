_ = require 'lodash'
{jobQueue} = require '../config/tables'
{crud} = require '../utils/crud/util.crud.service.helpers'

module.exports =
  taskHistory: crud(jobQueue.taskHistory, 'name')
  queues: crud(jobQueue.queueConfig, 'name')
  tasks: crud(jobQueue.taskConfig, 'name')
  subtasks: crud(jobQueue.subtaskConfig, 'name')
  summary: crud(jobQueue.jqSummary)
  health: crud(jobQueue.dataHealth)
