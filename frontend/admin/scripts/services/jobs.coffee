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

  getCurrent = () ->
    Restangular.all(jobsAPI).all('history').getList( current: true )

  getHistory = (taskName) ->
    Restangular.all(jobsAPI).all('history').getList( name: taskName )

  getHealth = (timerange) ->
    Restangular.all(jobsAPI).all('health').getList(timerange: timerange)

  getQueue = () ->
    Restangular.all(jobsAPI).all('queues').getList()

  getTask = () ->
    Restangular.all(jobsAPI).all('tasks').getList()

  getSubtask = () ->
    Restangular.all(jobsAPI).all('subtasks').getList()

  getSummary = () ->
    Restangular.all(jobsAPI).all('summary').getList()

  runTask = (task) ->
    task.post('run')

  cancelTask = (task) ->
    task.post('cancel')

  service =
    getCurrent: getCurrent
    getHistory: getHistory
    getHealth: getHealth
    getQueue: getQueue
    getTask: getTask
    getSubtask: getSubtask
    getSummary: getSummary
    runTask: runTask
    cancelTask: cancelTask
