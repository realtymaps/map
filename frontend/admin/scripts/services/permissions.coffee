app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsPermissionsService', (Restangular) ->

  api = backendRoutes.user_permissions.apiBase

  _init = () ->
    Restangular.all(api)

  get = (filters = {}) ->
    _init().getList(filters)

  return {
    get
  }
