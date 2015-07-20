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
    Restangular.all(jobsAPI).all('history').getList( status: 'running' )

  getHistory = (taskName) ->
    Restangular.all(jobsAPI).all('history').getList( name: taskName )

  getQueues = () ->
    Restangular.all(jobsAPI).all('queues').getList()

  getTasks = () ->
    Restangular.all(jobsAPI).all('tasks').getList()

  getSubtasks = () ->
    Restangular.all(jobsAPI).all('subtasks').getList()

  service =
    getCurrent: getCurrent
    getHistory: getHistory
    getQueues: getQueues
    getTasks: getTasks
    getSubtasks: getSubtasks
