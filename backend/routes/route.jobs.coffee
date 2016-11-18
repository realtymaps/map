jobs = require '../services/service.jobs'
{routeCrud, RouteCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
jobQueue = require '../services/service.jobQueue'
ExpressResponse = require '../utils/util.expressResponse'
logger = require('../config/logger').spawn('jobQueue:manual')


class JobCrud extends RouteCrud
  init: () ->
    @taskHistoryCrud = routeCrud(@svc.taskHistory, 'name')
    @subtaskErrorHistoryCrud = routeCrud(@svc.subtaskErrorHistory, 'name')
    @queueCrud = routeCrud(@svc.queues, 'name')
    @taskCrud = routeCrud(@svc.tasks, 'name')
    @subtaskCrud = routeCrud(@svc.subtasks, 'name')
    @summaryCrud = routeCrud(@svc.summary)
    @healthCrud = routeCrud(@svc.health)

    @taskHistory = @taskHistoryCrud.root
    @subtaskErrorHistory = @subtaskErrorHistoryCrud.root

    @queues = @queueCrud.root
    @queuesById = @queueCrud.byId

    @tasks = @taskCrud.root
    @tasksById = @taskCrud.byId

    @subtasks = @subtaskCrud.root
    @subtasksById = @subtaskCrud.byId

    @summary = @summaryCrud.root

    @health = @healthCrud.root

    @runTask = (req, res, next) ->
      jobQueue.queueManualTask(req.params.name, req.user.username)
      .then () ->
        next new ExpressResponse alert: {msg: "Started #{req.params.name}", type: 'rm-info'}

    @cancelTask = (req, res, next) ->
      logger.info("Cancelling task via admin: #{req.params.name} (requested by #{req.user.username})")
      jobQueue.cancelTask(req.params.name)
      .then () ->
        next new ExpressResponse alert: {msg: "Canceled #{req.params.name}", type: 'rm-warning'}

    super()


module.exports = mergeHandles new JobCrud(jobs),
  taskHistory:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  subtaskErrorHistory:
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
  health:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  runTask:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  cancelTask:
    methods: ['post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
