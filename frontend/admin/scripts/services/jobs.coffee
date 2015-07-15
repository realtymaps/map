app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsJobsService', (Restangular) ->

  jobsAPI = backendRoutes.jobs.apiBase

  getAll = () ->
    Restangular.all(jobsAPI).getList()

  service =
    getAll: getAll
