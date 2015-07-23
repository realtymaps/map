_ = require 'lodash'
jobs = require '../services/service.jobs'
{routeCrud, RouteCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'

class JobCrud extends RouteCrud
  init: () ->
    @taskHistoryCrud = routeCrud(@svc.taskHistory, 'name')
    @queueCrud = routeCrud(@svc.queues, 'name')
    @taskCrud = routeCrud(@svc.tasks, 'name')
    @subtaskCrud = routeCrud(@svc.subtasks, 'name')
    @summaryCrud = routeCrud(@svc.summary)

    @taskHistory = @taskHistoryCrud.root

    @queues = @queueCrud.root
    @queuesById = @queueCrud.byId

    @tasks = @taskCrud.root
    @tasksById = @taskCrud.byId

    @subtasks = @subtaskCrud.root
    @subtasksById = @subtaskCrud.byId

    @summary = @summaryCrud.root

    super()


module.exports = mergeHandles new JobCrud(jobs),
  taskHistory:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  queues:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  queuesById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  tasks:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  tasksById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  subtasks:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  subtasksById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  summary:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
