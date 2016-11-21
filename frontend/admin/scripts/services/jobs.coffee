app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsJobsService', (Restangular) ->

  jobsAPI = backendRoutes.jobs.apiBase
  getIdFromElem = Restangular.configuration.getIdFromElem
  Restangular.configuration.getIdFromElem = (elem) ->
    switch elem.route
      when 'queues', 'tasks', 'subtasks'
        elem.name
      else
        getIdFromElem(elem)

  Restangular.addRequestInterceptor (element, operation, what, url) ->
    if (operation == 'post' || operation == 'put') && (what == 'tasks' || what == 'subtasks')
      element.data = JSON.stringify(element.data)
    element

  getHistory = (filters = {}) ->
    Restangular.all(jobsAPI).all('history').getList(filters)

  getSubtaskErrorHistory = (filters = {}) ->
    Restangular.all(jobsAPI).all('subtaskerrorhistory').getList(filters)

  getSummary = () ->
    Restangular.all(jobsAPI).all('summary').getList()

  getHealth = (timerange) ->
    Restangular.all(jobsAPI).all('health').getList(timerange: timerange)

  runTask = (task) ->
    task.post('run')

  cancelTask = (task) ->
    task.post('cancel')


  getQueue = (filters) ->
    if filters?.search?
      filters.name = filters.search
      delete filters.search
    Restangular.all(jobsAPI).all('queues').getList(filters)

  getTask = (name) ->
    Restangular.all(jobsAPI).all('tasks').one(name).get()

  updateTask = (name, task) ->
    Restangular.all(jobsAPI).all('tasks').one(name).customPUT(task)

  getTasks = (filters) ->
    if filters?.search?
      filters.name = filters.search
      delete filters.search
    Restangular.all(jobsAPI).all('tasks').getList(filters)

  getSubtask = (filters) ->
    if filters?.search?
      filters.name = filters.search
      filters.task_name = filters.search
      delete filters.search
    Restangular.all(jobsAPI).all('subtasks').getList(filters)


  service =
    #getCurrent: getCurrent
    getHistory: getHistory
    getSubtaskErrorHistory: getSubtaskErrorHistory
    getHealth: getHealth
    getQueue: getQueue
    getTasks: getTasks
    getTask: getTask
    updateTask: updateTask
    getSubtask: getSubtask
    getSummary: getSummary
    runTask: runTask
    cancelTask: cancelTask
