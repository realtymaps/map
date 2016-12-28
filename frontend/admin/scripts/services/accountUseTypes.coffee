app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsAccountUseTypesService', (Restangular) ->

  api = backendRoutes.account_use_types.apiBase
  # getIdFromElem = Restangular.configuration.getIdFromElem
  #
  # Restangular.configuration.getIdFromElem = (elem) ->
  #   switch elem.route
  #     when 'customers', 'staff'
  #       elem.email
  #     else
  #       getIdFromElem(elem)

  _init = () ->
    Restangular.all(api)

  get = (filters = {}) ->
    _init().getList(filters)

  return {
    get
  }
