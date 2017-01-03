app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsUsersService', (Restangular) ->

  api = backendRoutes.user.apiBase
  getIdFromElem = Restangular.configuration.getIdFromElem

  Restangular.configuration.getIdFromElem = (elem) ->
    switch elem.route
      when 'customers', 'staff'
        elem.email
      else
        getIdFromElem(elem)

  _init = () ->
    Restangular.all(api)

  get = (filters = {}) ->
    _init().getList(filters)

  subResource = (resource) ->
    _init().all(resource)

  getGroups = (filters = {}) ->
    subResource('groups').getList(filters)

  getPermissions = (filters = {}) ->
    subResource('permissions').getList(filters)

  updatePermission = (name, permission) ->
    subResource('permissions').one(name).customPUT(permission)

  return {
    get
    getGroups
    getPermissions
    updatePermission
  }
