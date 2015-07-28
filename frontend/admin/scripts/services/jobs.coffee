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

  getCurrent = () ->
    Restangular.all(jobsAPI).all('history').getList( current: true )

  getHistory = (taskName) ->
    Restangular.all(jobsAPI).all('history').getList( name: taskName )

  getQueue = () ->
    Restangular.all(jobsAPI).all('queues').getList()

  getTask = () ->
    Restangular.all(jobsAPI).all('tasks').getList()

  getSubtask = () ->
    Restangular.all(jobsAPI).all('subtasks').getList()

  getSummary = () ->
    Restangular.all(jobsAPI).all('summary').getList()

  service =
    getCurrent: getCurrent
    getHistory: getHistory
    getQueue: getQueue
    getTask: getTask
    getSubtask: getSubtask
    getSummary: getSummary
