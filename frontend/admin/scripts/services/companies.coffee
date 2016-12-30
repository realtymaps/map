app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsCompanyService', (Restangular) ->

  api = backendRoutes.company.apiBase

  _init = () ->
    Restangular.all(api)

  get = (filters = {}) ->
    _init().getList(filters)

  return {
    get
  }
