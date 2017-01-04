app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsGroupsService', (Restangular) ->

  api = backendRoutes.user_groups.apiBase

  _init = () ->
    Restangular.all(api)

  get = (filters = {}) ->
    _init().getList(filters)

  return {
    get
  }
