_ = require 'lodash'
jobs = require '../services/service.jobs'
{routeCrud, RouteCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
jobQueue = require '../utils/util.jobQueue'
userSession =  require '../services/service.userSession'
ExpressResponse = require '../utils/util.expressResponse'

class JobCrud extends RouteCrud
  init: () ->
    @taskHistoryCrud = routeCrud(@svc.taskHistory, 'name')
    @queueCrud = routeCrud(@svc.queues, 'name')
    @taskCrud = routeCrud(@svc.tasks, 'name')
    @subtaskCrud = routeCrud(@svc.subtasks, 'name')
    @summaryCrud = routeCrud(@svc.summary)
    @healthCrud = routeCrud(@svc.health)

    @taskHistory = @taskHistoryCrud.root

    @queues = @queueCrud.root
    @queuesById = @queueCrud.byId

    @tasks = @taskCrud.root
    @tasksById = @taskCrud.byId

    @subtasks = @subtaskCrud.root
    @subtasksById = @subtaskCrud.byId

    @summary = @summaryCrud.root

    @health = @healthCrud.root

    self = @

    @runTask = (req, res, next) ->
      jobQueue.queueManualTask(req.params.name, req.user.username)
      .then () ->
        next new ExpressResponse alert: msg: "Started #{req.params.name}"
      .catch _.partial(self.onError, next)

    @cancelTask = (req, res, next) ->
      jobQueue.cancelTask(req.params.name, 'canceled')
      .then () ->
        next new ExpressResponse alert: msg: "Canceled #{req.params.name}"
      .catch _.partial(self.onError, next)

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
