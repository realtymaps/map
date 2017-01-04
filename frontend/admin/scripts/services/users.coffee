app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'


app.service 'rmapsUsersService', ($q, Restangular) ->

  api = backendRoutes.user.apiBase
  getIdFromElem = Restangular.configuration.getIdFromElem

  Restangular.configuration.getIdFromElem = (elem) ->
    switch elem.route
      when 'customers', 'staff'
        elem.email
      else
        getIdFromElem(elem)

  Restangular.addRequestInterceptor  (element, operation, what, url) ->
    if ['put', 'post'].indexOf(operation) > -1
      #remove fk fields upon saving
      #upon saving groups or permissions they should route to their specific route /api/permissions , /api/groups
      delete element.permissions
      delete element.groups
    return element


  get = (filters = {}) ->
    Restangular.all(api).getList(filters)

  getGroups = (entity, filters = {}) ->
    entity.all('groups').getList(filters)

  getPermissions = (entity, filters = {}) ->
    entity.all('permissions').getList(filters)

  return {
    get
    getPermissions
    getGroups
  }
